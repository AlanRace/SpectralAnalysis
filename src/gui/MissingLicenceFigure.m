classdef MissingLicenceFigure < Figure
    %MissingLicenceFigure Interface to inform the user about missing licence
    %   
    
    properties (Constant)
        messageText = ['SpectralAnalysis is free to use and all functionality is included. However by registering, faster implementations of key features will be unlocked.\n\n' ...
            'To register, fill in the form below and email the result to registerSpectralAnalysis@gmail.com'];
        
        emailTemplate = ['Name: %s\nEmail: %s\nInstitution: %s\n\nInstance ID: %s\n'];
    end
    
    properties
        messageLabel;
        
        emailMessage;
        emailMessageBox;
        
        importLicenceButton;
        
        name = '';
        email = '';
        institution = '';
    end
    
    methods
        function this = MissingLicenceFigure()

            this.setTitle('No Licence File Found');
            this.updateEmailMessage()
        end
        
        function updateEmailMessage(this)
            this.emailMessage = sprintf(MissingLicenceFigure.emailTemplate, this.name, this.email, this.institution, ...
                com.alanmrace.spectralanalysislicence.EncryptLibrary.getLicenceText());
            
            set(this.emailMessageBox, 'String', this.emailMessage);
        end
        
        function importLicence(this)
            [fileName, pathName, filterIndex] = uigetfile(['SpectralAnalysis.lic'], 'Select licence file');
            
            if(filterIndex > 0)
                destination = '';
                
                if(isdeployed())
                    destination = [ctfroot() filesep '..' filesep 'SpectralAnalysis.lic'];
                else
                    destination = [getLibraryPath() filesep 'licence' filesep 'SpectralAnalysis.lic'];
                end
                
                copyfile([pathName filesep fileName], destination);
                
                this.delete();
            end
        end
    end
    
    methods (Access = protected)
        function createFigure(this)
            % createFigure Create figure.
            %
            %   createFigure()
            
            createFigure@Figure(this);
            
            this.messageLabel = uicontrol(this.handle, 'Style', 'text', 'String', sprintf(MissingLicenceFigure.messageText), ...
                'HorizontalAlignment', 'left', 'Position', [50 10 500 350]);
            
            this.emailMessageBox = uicontrol(this.handle, 'Style', 'edit', 'String', '', ...
                 'HorizontalAlignment', 'left', 'Max', 2, 'Position', [50 100 450 100]);            
            
            this.importLicenceButton = uicontrol(this.handle, 'String', 'Import Licence', ...
                'Position', [400 25 100 50], 'Callback', @(src, evnt)this.importLicence);
             
            %this.listBox = uicontrol(this.handle, 'Style', 'listbox', 'Units', 'Pixels', ...
            %    'Position', [10 10 450 300]);
            
            %this.closeDataButton = uicontrol(this.handle, 'Units', 'Pixels', ...
            %    'Position', [470 90 60 20], 'String', 'Close Data');
        end
    end
    
end

