% Example_5_JBAY: Mesh the New York Jamaica bay (JBAY) region in
% high resolution.

clearvars; clc; close all

PREFIX = '5_JBAY';

%% STEP 1: set mesh extents and set parameters for mesh.
bbox = [
    -73.97 -73.75   % lon_min lon_max
    40.5 40.68      % lat_min lat_max
    ];
min_el = 15.0;      % Minimum resolution in meters.
max_el = 1e3;
dt = 2;             % Ensure mesh is stable at a 2 s timestep
grade = 0.15;       % Mesh grade in decimal percent.
R = 3;              % Number of elements to resolve feature width.

%% STEP 2: specify geographical datasets and process the geographical data
% to be used later with other OceanMesh classes...
coastline = 'PostSandyNCEI';
dem = 'PostSandyNCEI.nc';

gdat = geodata(...
    'shp',coastline,...
    'dem',dem,...
    'bbox',bbox,...
    'h0',min_el);

%% STEP 3: create an edge function class
fh = edgefx(...
    'geodata',gdat,...
    'fs',R,...
    'dt',dt,...
    'max_el',max_el,...
    'g',grade);

%% STEP 4: Pass your edgefx class object along with some meshing options and
% build the mesh...
mshopts = meshgen('ef',fh,'bou',gdat,'plot_on',1,'proj','utm');
% now build the mesh with your options and the edge function.
mshopts = mshopts.build;

%% STEP 5: Plot it and save the msh file
% Get out the msh class and put on bathy and nodestrings
m = mshopts.grd;
m = interp(m,gdat,'nan','fill','mindepth',1); % interpolate bathy to the
% mesh with fill nan option to make sure corners get values
m = make_bc(m,'auto',gdat,'depth',5); % make the nodestring boundary conditions
% with depth cutoff for open boundary set to 5 m

plot(m,'type','bd'); % plot triangulation with boundary conditions
plot(m,'type','blog'); % plot bathy on log scale

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
