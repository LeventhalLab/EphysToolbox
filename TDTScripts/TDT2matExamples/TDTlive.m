classdef TDTlive < handle
    %TDTlive  TDT online data streamer.
    %   obj = TDTlive() connects to TTank server and opens currently
    %   recording block in Workbench
    %
    %   obj.data    reference to all available data from block
    %   obj.update  get latest data from current block
    %   obj.TT      reference to TTankX object, if custom calls are needed
    %
    
    properties
        TT;
        TD;
        SERVER = 'Local';
        NAME = 'Matlab';
        TANK = '';
        BLOCK = '';
        TYPE = [2 3 4]; % see TDT2mat help for TYPE information
        MAXEVENTS = 1e6;
        TIMESTAMPSONLY = false; % see TDT2mat help for NODATA
        NEWONLY = 1; % only return new data, otherwise return all data.
        VERBOSE = 1;
        CURRTIME = 0; % placeholders for time filters
        PREVTIME = 0; % placeholders for time filters
        data = [];
    end
    methods
        function obj = TDTlive()
            
            % create TTankX object
            %h = figure('Visible', 'off', 'HandleVisibility', 'off');
            obj.TT = actxserver('TTank.X');
            
            obj.TD = TDEV();
            obj.TANK = obj.TD.tank;
            
            % connect to server
            if obj.TT.ConnectServer(obj.SERVER, obj.NAME) ~= 1
                error(['Problem connecting to server: ' obj.SERVER])
            end
            
            % open tank
            if obj.TT.OpenTank(obj.TANK, 'r') ~= 1
                obj.TT.ReleaseServer;
                error(['Problem opening tank: ' obj.TANK]);
            end
            
            % select block
            obj.BLOCK = obj.TT.GetHotBlock();
            
            if obj.TT.SelectBlock(obj.BLOCK) ~= 1
                if obj.TD.TD.GetSysMode < 2
                    error('Workbench not currently recording');
                else
                    error('Problem selecting current block');
                end
            else
                disp(['Connected to TANK:' obj.TANK ', BLOCK:' obj.BLOCK]);
            end

            % wait until data is available, which is after the cache delay
            % time has elapsed
            fprintf('Waiting for initial data...');
            x = obj.TT.GetValidTimeRangesV();
            while isnan(x)
                 fprintf('.');
                 pause(.5)
                 x = obj.TT.GetValidTimeRangesV();
            end
            %obj.update();
            fprintf('\n');
        end
        
        function delete(obj)
            %obj.TT.CloseTank;
            %obj.TT.ReleaseServer;
        end
        
        function obj = update(obj)
            
            % get latest data
            x = obj.TT.GetValidTimeRangesV();
            
            if numel(x) == 1
                pause(.5)
                if obj.TD.TD.GetSysMode == 0
                    error('Valid Time Range is NaN, block has stopped')
                else
                    error('Valid Time Range is NaN')
                end
            end
            
            obj.CURRTIME = x(2);
            if obj.NEWONLY 
                T1 = obj.PREVTIME;
            else
                T1 = 0;
            end
            
            obj.data = TDT2mat(...
                obj.TANK, ...
                obj.BLOCK, ...
                'VERBOSE', false, ...
                'TTX', obj.TT, ...
                'TYPE', obj.TYPE, ...
                'T1', T1, ...
                'T2', obj.CURRTIME, ...
                'NODATA', obj.TIMESTAMPSONLY ...
                );
            obj.PREVTIME = obj.CURRTIME;
            
            % reset globals (do this inside TDT2mat?)
            obj.TT.SetGlobalV('T1', 0);
            obj.TT.SetGlobalV('T2', 0);
            
            % TODO: trim zeros from end of streams that were added by 
            % ReadWavesV?
            %for f = fields(t.data.streams)'
            %    name = f{:};
            %    obj.data.streams.(name).data
            %    if obj.data.streams.(name).data(1,end) == 0
            %end   
            
            %TODO: display # of read events if obj.VERBOSE
        end
    end
end