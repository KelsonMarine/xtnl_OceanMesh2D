% Example_6b_GBAY_w_floodplain
% Continue on from Example_6_GBAY.m by building on
% a floodplain onto the mesh.

% Most mesh sizing functions can be enforced in a
% topographic elevation (-1*depth) range such as:
%
% sizing_parameter = [size_value1, z_min1, z_max1;
%                     size_value2, z_min2, z_max2;
%                    ];
% Note: multiple elevation ranges must be delineated with semi-colons ;

clearvars; clc; close all

PREFIX = '6_GBAY_w_floodplain';

%% STEP 1: set mesh extents and set parameters for mesh.
min_el = 60;            % Minimum mesh resolution in meters.
max_el = [
    1e3 -inf 0          % Underwater maximum mesh resolution in meters.
    500 0 +inf          % Overland maximum mesh resolution in meters.
    ];
grade = [
    0.25 -inf 0         % Underwater gradation rate
    0.05 0 +inf         % Overland gradation rate
    ];
angleOfReslope = 60;    % Control width of channel by changing angle of reslope.
ch = 0.1;               % Scale resolution propotional to depth nearby thalweg.
fs = 3 ;                % Place 3 vertices per width of shoreline feature.

%% STEP 2: specify geographical datasets and process the geographical data
% to be used later with other OceanMesh classes...
coastline = 'us_medium_shoreline_polygon';
demfile   = 'galveston_13_mhw_2007.nc';

gdatuw = geodata(...
    'shp',coastline,...
    'dem',demfile,...
    'h0',min_el);

load ECGC_Thalwegs.mat % Load the Channel thalweg data

%% STEP 3: create an edge function class
fh = edgefx(...
    'geodata',gdatuw,...
    'fs',fs,...
    'ch',ch,...
    'AngOfRe',angleOfReslope,...% control the width
    'Channels',pts2,...
    'g',grade,...
    'max_el',max_el);

%% STEP 4: Pass your edgefx class object along with some meshing options and
% build the mesh...
mshopts = meshgen('ef',fh,'bou',gdatuw,'plot_on',1,'proj','lambert');
% now build the mesh with your options and the edge function.
mshopts = mshopts.build;

%% STEP 5: Get fixed constraints and update gdat with overland meshing domain.
muw = mshopts.grd ;
muw = makens(muw,'auto',gdatuw) ; % apply so that extractFixedConstraints only grabs the shoreline constraints.

[pfix,egfix] = extractFixedConstraints(muw) ;

% 10-m contour extracted from the Coastal Relief Model.
coastline = 'us_coastalreliefmodel_10mLMSL';
demfile = 'galveston_13_mhw_2007.nc';
landuse = 'galveston_2016_CCAP.nc';

gdat = geodata(...
    'shp',coastline,...
    'dem',demfile,...
    'h0',min_el);

%gdat.inpoly_flip =  mod(1,gdat.inpoly_flip) ; % if the meshing domain is inverted, you can always flip it .

% Here we pass our constraints to the mesh generator (pfix and egfix).
mshopts = meshgen('ef',fh,'bou',gdat,'plot_on',1,'proj','lambert',...
    'pfix',pfix,'egfix',egfix);

% now build the mesh with your options and the edge function.
mshopts = mshopts.build;

m = mshopts.grd;

% plot resolution on the mesh
plot(m,'type','resomesh','colormap',[10 0 1e3]);

% interpolate bathy using special constraining technique
% for overland and underwater
m = interpFP(m,gdat,muw,gdatuw);
plot(m,'type','bmesh'); % plot the bathy on the mesh

% computing mannings based on CCAP landcover data using
% cell-averaged interpolation with stencil 4*grid_size for stability
m = Calc_Mannings_Landcover(m,landuse,'ccap','N',4);
plot(m,'type','mann'); % plot the mannings on the mesh

%% Export plots
figs = get(0,'children');
for f = 1:numel(figs)
    fname = sprintf('%s_plot%i',PREFIX,figs(f).Number);
    print(figs(f).Number,fname,'-dpng','-r200');
end

%% Save mesh files
% Save as a msh class
save(sprintf('%s_msh.mat',PREFIX),'m');
% Write an ADCIRC fort.14 compliant file to disk.
write(m,sprintf('%s_mesh',PREFIX))
