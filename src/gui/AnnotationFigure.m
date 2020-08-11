classdef AnnotationFigure < Figure
    
    properties 
        peaks;
        adducts;
        ppmTolerance;
        
        ppmToleranceLabel;
        ppmToleranceEditbox;
        
        polarityButtonGroup;
        positiveButton;
        negativeButton;
        matchButton;
        
        peakListTable;
        toAnnotateLabel;
        possibleAnnotationTable;
        
        possibleAssignments;
        
        structureAxis;
    end
    
    properties (Access = protected)
        smilesParser;
    end
    
    methods
        function this = AnnotationFigure(peaks)
            this.peaks = peaks;
            
            this.setTitle('Annotate Peaks');
            
            this.sizeChanged();
            
            
            objectBuilder = org.openscience.cdk.DefaultChemObjectBuilder.getInstance();
            this.smilesParser = org.openscience.cdk.smiles.SmilesParser(objectBuilder);
        end
        
        function setAnnotationProperties(this, adducts, ppm)
            numPossibleAssignments = HMDBGetNumberAnnotations(this.peaks, adducts, ppm);
            
            dataList = {};
            
            for i = 1:length(this.peaks)
                dataList(i, 1) = {this.peaks(i).getDescription()};
                dataList(i, 6) = {num2str(numPossibleAssignments(i))};
            end
            
            set(this.peakListTable, 'Data', dataList);
        end
        
        function useUIFigure = isUIFigure(this)
            useUIFigure = true;
        end
        
    end
    
    methods (Access = protected)
        function createFigure(this)
            % createFigure Create figure.
            %
            %   createFigure()
            
            createFigure@Figure(this);
            
            this.setWidth(800);
            
            this.ppmToleranceLabel = uilabel(this.handle, 'Text', 'PPM');
            this.ppmToleranceEditbox = uieditfield(this.handle, 'numeric', 'Value', 3);
            
            this.polarityButtonGroup = uibuttongroup(this.handle);
            this.positiveButton = uiradiobutton(this.polarityButtonGroup, 'Text', 'Positive (+H, +Na, +K)');
            this.negativeButton = uiradiobutton(this.polarityButtonGroup, 'Text', 'Negative');
            
            this.matchButton = uibutton(this.handle, 'Text', 'Match', ...
                'ButtonPushedFcn', @(src, event) this.matchButtonPushed(src, event));
            
            this.peakListTable = uitable('Parent', this.handle, 'RowName', [], ...
                    'ColumnName', {'Peak', 'Assignment', 'Adduct', 'Theoretical m/z', 'Mass Deviation (PPM)', '# Possible Annotations'}, ...
                    'ColumnFormat', {'char', 'char', 'char', 'numeric', 'numeric', 'numeric'}, ...
                    'ColumnEditable', [false, false], ...
                    'ColumnWidth', {120, 120, 90, 100, 130, 160} , ...
                    'CellSelectionCallback', @(src, evnt) this.peakListTableSelected(src, evnt));
                
            if this.isUIFigure
                this.peakListTable.ColumnSortable = [true, true, true, true, true, true];
            end
            
            this.toAnnotateLabel= this.createLabel(this.handle, '', 'left');
            
            this.possibleAnnotationTable = uitable('Parent', this.handle, 'RowName', [], ...
                    'ColumnName', {'HMBD ID', 'Name', 'Adduct', 'Theoretical m/z', 'Mass Deviation (PPM)', ...
                    'Kingdom', 'Super Class', 'Class', 'Sub Class', 'Direct Parent'}, ...
                    'ColumnFormat', {'char', 'char', 'char', 'numeric', 'numeric'}, ...
                    'ColumnEditable', [false, false], ...
                    'ColumnWidth', {120, 200, 90, 100, 130, 160} , ...
                    'CellSelectionCallback', @(src, evnt) this.annotationSelected(src, evnt));
                
            if this.isUIFigure
                this.possibleAnnotationTable.ColumnSortable = [true, true, true, true, true, true, true, true, true, true];
            end
            
            this.structureAxis = uiaxes(this.handle);
        end
        
        function matchButtonPushed(this, src, event)
            this.adducts = [Adduct('+H', 'H', 1.00782503223), Adduct('+Na', 'Na', 22.9897692820), Adduct('+K', 'K',  38.9637064864)];
            this.ppmTolerance = get(this.ppmToleranceEditbox, 'Value');
            
            this.setAnnotationProperties(this.adducts, this.ppmTolerance);
        end
        
        function peakListTableSelected(this, src, event)
            selectedPeak = this.peaks(event.Indices(1));
            
            labelText = ['Selecting annotation for ' num2str(selectedPeak.centroid, '%.5f')];
            if this.isUIFigure()
                this.toAnnotateLabel.Text = labelText;
            else
                set(this.toAnnotateLabel, 'String', labelText);
            end
            
            this.possibleAssignments = HMDBGetPossibleAnnotations(selectedPeak, this.adducts, this.ppmTolerance);
            
            dataList = {};
            
            for i = 1:length(this.possibleAssignments)
                dataList(i, 1) = {this.possibleAssignments(i).hmdbID};
                dataList(i, 2) = {this.possibleAssignments(i).name};
                dataList(i, 3) = {this.possibleAssignments(i).adduct.description};
                dataList(i, 4) = {this.possibleAssignments(i).getMonoisotopicMass()};
                dataList(i, 5) = {(this.possibleAssignments(i).getMonoisotopicMass() - selectedPeak.centroid) / this.possibleAssignments(i).getMonoisotopicMass() * 1e6};
                dataList(i, 6) = {this.possibleAssignments(i).kingdom};
                dataList(i, 7) = {this.possibleAssignments(i).superClass};
                dataList(i, 8) = {this.possibleAssignments(i).class};
                dataList(i, 9) = {this.possibleAssignments(i).subClass};
                dataList(i, 10) = {this.possibleAssignments(i).directParent};
            end
            
            set(this.possibleAnnotationTable, 'Data', dataList);
        end
        
        function annotationSelected(this, src, event)
            possibleAssignment = this.possibleAssignments(event.Indices(1));
            
            % Draw the chemical structure using CDK
            molecule = this.smilesParser.parseSmiles(possibleAssignment.smiles);

            positionStructureAxis = get(this.structureAxis, 'Position');
            imageSize = min([positionStructureAxis(3) positionStructureAxis(4)]);

            width = imageSize*2;
            height = imageSize*2;

            dg = org.openscience.cdk.depict.DepictionGenerator();
            dg = dg.withAtomColors();
            dg = dg.withSize(width, height);
            dg = dg.withFillToFit();

            depiction = dg.depict(molecule);

            image = depiction.toImg();

            width = image.getWidth();
            height = image.getHeight();

            imageData = zeros([height, width, 3], 'uint8');
            pixelsData = reshape(typecast(image.getData.getDataStorage,'uint32'), width, height).';
            alpha = bitshift(bitand(pixelsData,256^1-1),-8*0);
            imageData(:,:,3) = bitshift(bitand(pixelsData,256^2-1),-8*1);
            imageData(:,:,2) = bitshift(bitand(pixelsData,256^3-1),-8*2);
            imageData(:,:,1) = bitshift(bitand(pixelsData,256^4-1),-8*3);

            % imshow(imageData, 'Parent', this.structureAxis);
            imagesc(this.structureAxis, imageData)
            axis(this.structureAxis, 'image');
            axis(this.structureAxis, 'off');
        end
        
        function sizeChanged(this, src, evnt)
            if(this.handle ~= 0)
                oldUnits = get(this.handle, 'Units');
                set(this.handle, 'Units', 'pixels');
            
                newPosition = get(this.handle, 'Position');
                
                margin = this.defaultMargin;
                usableWidth = newPosition(3) - margin*2;
                usableHeight = newPosition(4) - margin*2;
                
                editBoxSize = this.defaultEditBoxSize;
                
                radioGroupWidth = 300;
                
                Figure.setObjectPositionInPixels(this.ppmToleranceLabel, [margin, usableHeight-editBoxSize+margin, usableWidth, editBoxSize]);
                Figure.setObjectPositionInPixels(this.ppmToleranceEditbox, [margin+40, usableHeight-editBoxSize+margin, 50, editBoxSize]);
                
                Figure.setObjectPositionInPixels(this.polarityButtonGroup, [margin*2+90, usableHeight-editBoxSize+margin, radioGroupWidth, editBoxSize]);
                Figure.setObjectPositionInPixels(this.positiveButton, [margin, margin, radioGroupWidth/2-margin, editBoxSize-margin*2]);
                Figure.setObjectPositionInPixels(this.negativeButton, [radioGroupWidth/2+margin, margin, radioGroupWidth/2-margin, editBoxSize-margin*2]);
                
                Figure.setObjectPositionInPixels(this.matchButton, [margin*3+90+radioGroupWidth, usableHeight-editBoxSize+margin, 80, editBoxSize]);
                
                
                Figure.setObjectPositionInPixels(this.peakListTable, [margin, usableHeight*2/3+margin*2, usableWidth, usableHeight/3 - (editBoxSize+margin*2)]);
                Figure.setObjectPositionInPixels(this.toAnnotateLabel, [margin, usableHeight/3+margin*2, usableWidth, this.defaultLabelSize]);
                
                thirdHeight = usableHeight/3-margin;
                
                Figure.setObjectPositionInPixels(this.possibleAnnotationTable, [margin, margin, usableWidth-thirdHeight, thirdHeight]);
                Figure.setObjectPositionInPixels(this.structureAxis, [margin*2+usableWidth-thirdHeight, margin, thirdHeight, thirdHeight]);
            end
             
            sizeChanged@Figure(this);
        end
    end
    
end