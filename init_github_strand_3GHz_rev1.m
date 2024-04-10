clear;
clc;
close all;
top_start_clock=clock;
app=NaN(1);
folder1='C:\Local Matlab Data\3GHz Strand Deployment';
cd(folder1)
addpath(folder1)
pause(0.1)
addpath('C:\Local Matlab Data\General_Terrestrial_Pathloss') %%% https://github.com/nicklasorte/general_terrestrial_pathloss
addpath('C:\Local Matlab Data\General_Movelist') %%%https://github.com/nicklasorte/General_Movelist

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Strand Mount Deployment Example 
%%%%%%%%%%%%Portal DPA Information: https://ntia.gov/sites/default/files/publications/p-dpas.kml
min_ant_loss=25; %%%%%%%%Main to side gain: 25dB
moorestown_dpa_data=horzcat(39.98,-74.90138889,25,-144,90,181,3,min_ant_loss)
%%%%%%1)Latitude
%%%%%%2)Longitude
%%%%%%3)Antenna Height (m)
%%%%%%4)DPA Threshold: dbm/10MHz
%%%%%%5)Min Azimuth (0 is True North)
%%%%%%6)Max Azimuth
%%%%%%7)Antenna Horizontal Beamwidth [degrees]

%%%%%%%%%%%%%%%%%%%%'Pull in the census tracts filtered by Urban areas'
tic;
load('Cascade_new_full_census_2010.mat','new_full_census_2010')%%%%%%%Geo Id, Center Lat, Center Lon,  NLCD (1-4), Population
load('census_ua_2010.mat','census_ua_2010')
toc;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Just a placeholder
norm_aas_zero_elevation_data=[-180:1:180]';
norm_aas_zero_elevation_data(:,2)=0;
norm_aas_zero_elevation_data(:,3)=0;
norm_aas_zero_elevation_data(:,4)=0;
max(norm_aas_zero_elevation_data(:,[2:4])) %%%%%This should be [0 0 0]
%%%%1) Horizontal Azimuth -180~~180
%%%2) Rural
%%%3) Suburban
%%%4) Urban





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Make a Simulation Folder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rev=101; %%%%%%Example of Moorestown with Strand Mount
cell_name=cell(1,1);
cell_name{1}='Moorestown';
cell_dpa_geo=horzcat(cell_name,num2cell(moorestown_dpa_data))
freq_separation=0; %%%%%%%Assuming co-channel
network_loading_reduction=8;  %%%%%%%%%%
array_bs_eirp=ones(1,3).*[47:1:57]' %%%%%dBm/10MHz %%%%%EIRP [dBm/10MHz] for Rural, Suburan, Urban 
array_bs_eirp_reductions=(array_bs_eirp-network_loading_reduction) %%%%%Rural, Suburban, Urban cols:(1-3), No Mitigations/Mitigations rows:(1-2)
tf_clutter=1;  %%%%%%P2108
base_station_height=5%%%%5 meters
deployment_percentage=100;  %%%%%%%%%%%%Value from 1-100% (randomly selects from the possible list if less than 100%
sim_radius_km=200; %%%%%%%%km
sim_folder1=folder1
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Propagation Inputs/Other Inputs
FreqMHz=3550; %%%%%%%%MHz
reliability=50; %%%A custom ITM range where we will make rings for each reliability
confidence=50; %%%%%%%%ITM Confidence
Tpol=1; %%%polarization for ITM
mc_size=1;
mc_percentile=100; %%%%95th Percentile (if 50% ITM, set mc_percentile=100 and mc_size=1)
building_loss=15;  %%%%%%%%Only for indoor deployment
tf_opt=0; %%%%%%%%%0==CBRS move list order
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%Create a Rev Folder
cd(sim_folder1);
pause(0.1)
tempfolder=strcat('Rev',num2str(rev));
[status,msg,msgID]=mkdir(tempfolder);
rev_folder=fullfile(sim_folder1,tempfolder);
cd(rev_folder)
pause(0.1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Saving the simulation files in a folder for the option to run from a server
save('cell_dpa_geo.mat','cell_dpa_geo')
save('reliability.mat','reliability')
save('confidence.mat','confidence')
save('FreqMHz.mat','FreqMHz')
save('Tpol.mat','Tpol')
save('building_loss.mat','building_loss')
save('tf_opt.mat','tf_opt')
save('mc_percentile.mat','mc_percentile')
save('mc_size.mat','mc_size')
save('deployment_percentage.mat','deployment_percentage')
save('building_loss.mat','building_loss')
save('sim_radius_km.mat','sim_radius_km')
save('array_bs_eirp_reductions.mat','array_bs_eirp_reductions') %%%%%Rural, Suburban, Urban cols:(1-3), No Mitigations/Mitigations rows:(1-2)
save('array_bs_eirp.mat','array_bs_eirp')
save('norm_aas_zero_elevation_data.mat','norm_aas_zero_elevation_data')
save('tf_clutter.mat','tf_clutter')

%%%%%%%%%%%%%
[num_loc,~]=size(cell_dpa_geo);
location_table=table([1:1:num_loc]',cell_dpa_geo(:,1))
array_bs_latlon=census_ua_2010(:,[2:3]);
size(array_bs_latlon)



for base_idx=1:1:num_loc
    temp_cell_geo_data=cell_dpa_geo(base_idx,:)
    data_label1=erase(temp_cell_geo_data{1}," ");  %%%Remove the Spaces
    
    %%%%%%%%%Step 1: Make a Folder for this single DPA
    cd(rev_folder);
    pause(0.1)
    tempfolder2=strcat(data_label1);
    [status,msg,msgID]=mkdir(tempfolder2);
    sim_folder=fullfile(rev_folder,tempfolder2);
    cd(sim_folder)
    pause(0.1)
        
    temp_lat=temp_cell_geo_data{2};  
    temp_lon=temp_cell_geo_data{3};  
    temp_radar_height=temp_cell_geo_data{4};  

    base_polygon=horzcat(temp_lat,temp_lon,temp_radar_height)
    base_protection_pts=base_polygon;
    save(strcat(data_label1,'_base_polygon.mat'),'base_polygon')
    save(strcat(data_label1,'_base_protection_pts.mat'),'base_protection_pts') %%%%%Save the Protection Points
    
    
    radar_threshold=temp_cell_geo_data{5};
    min_azimuth=temp_cell_geo_data{6};
    max_azimuth=temp_cell_geo_data{7};
    radar_beamwidth=temp_cell_geo_data{8};
    min_ant_loss=temp_cell_geo_data{9};

    save(strcat(data_label1,'_radar_threshold.mat'),'radar_threshold')
    save(strcat(data_label1,'_radar_beamwidth.mat'),'radar_beamwidth')
    save(strcat(data_label1,'_min_ant_loss.mat'),'min_ant_loss')
    save(strcat(data_label1,'_min_azimuth.mat'),'min_azimuth')
    save(strcat(data_label1,'_max_azimuth.mat'),'max_azimuth')



% %     figure;
% %     hold on;
% %     plot(base_polygon(:,2),base_polygon(:,1),'-r')
% %     plot(base_protection_pts(:,2),base_protection_pts(:,1),'ok')
% %     grid on;
% %     size(base_protection_pts)
% %     plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
% %     filename1=strcat('Operational_Area_',data_label1,'.png');
% %     pause(0.1)
% %     %saveas(gcf,char(filename1))


    %%%%%%%%Sim Bound
    if any(isnan(base_polygon))
        nan_base_polygon=base_polygon(~isnan(base_polygon(:,1)),:);
    else
        nan_base_polygon=base_polygon;
    end
    [sim_bound]=calc_sim_bound(app,nan_base_polygon,sim_radius_km,data_label1);

    %%%%%%%Filter Base Stations that are within sim_bound
    tic;
    bs_inside_idx=find(inpolygon(array_bs_latlon(:,2),array_bs_latlon(:,1),sim_bound(:,2),sim_bound(:,1))); %Check to see if the points are in the polygon
    toc;
    size(bs_inside_idx)
    temp_sim_bs_data=array_bs_latlon(bs_inside_idx,:);


    %%%%%%%%%%%%Downsample deployment
    [num_inside,~]=size(bs_inside_idx)
    sample_num=ceil(num_inside*deployment_percentage/100)
    rng(rev+base_idx); %%%%%%%For Repeatibility
    rand_sample_idx=datasample(1:num_inside,sample_num,'Replace',false);
    size(temp_sim_bs_data)
    temp_sim_bs_data=temp_sim_bs_data(rand_sample_idx,:);
    size(temp_sim_bs_data)
    

    figure;
    hold on;
    plot(temp_sim_bs_data(:,2),temp_sim_bs_data(:,1),'ob')
    plot(sim_bound(:,2),sim_bound(:,1),'-r','LineWidth',3)
    plot(base_protection_pts(:,2),base_protection_pts(:,1),'sr','Linewidth',4)
    grid on;
    plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
    filename1=strcat('Sim_Area_Deployment_',data_label1,'.png');
    pause(0.1)
    saveas(gcf,char(filename1))
    pause(0.1)


    %%%%%%%%%%%%%%%Also include the array of the list_catb (order) that we
    %%%%%%%%%%%%%%%usually use for the other sims. (As this will be used
    %%%%%%%%%%%%%%%for the path loss and move list.)

    [num_tx,~]=size(temp_sim_bs_data)
    sim_array_list_bs=horzcat(temp_sim_bs_data,NaN(num_tx,5));
    [num_bs_sectors,~]=size(sim_array_list_bs);
    sim_array_list_bs(:,4)=array_bs_eirp_reductions(1,1);
    sim_array_list_bs(:,5)=1:1:num_bs_sectors;
    sim_array_list_bs(:,6)=3;
    sim_array_list_bs(:,7)=0;
    % % %      %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP Adjusted 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth 
    %%%%%%%%If there is no mitigation EIRPs, make all of these NaNs (column 8)

    %%%%%%%%%%%Put the rest of the Link Budget Parameters in this list
    sim_array_list_bs(1,:)
    size(sim_array_list_bs)


    if ~isnan(base_station_height)
        sim_array_list_bs(:,3)=base_station_height;
        unique(sim_array_list_bs(:,3))
        %pause;
    end
    unique(sim_array_list_bs(:,3))

    tic;
    save(strcat(data_label1,'_sim_array_list_bs.mat'),'sim_array_list_bs')
    toc; %%%%%%%%%3 seconds
    % % %      %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP Adjusted 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth 8)BS EIRP Mitigation

    'Check for nans in power'
    unique(sim_array_list_bs(:,4))
    any(isnan(sim_array_list_bs(:,4)))

    strcat(num2str(base_idx/num_loc*100),'%')

end
cd(folder1);
pause(0.1)








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Run the simulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parallel_flag=0%1%0%1%0%1%0%1%0%1%0%1 %%%%%0 --> serial, 1 --> parallel
tf_server_status=0;
tf_recalculate=0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%App Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RandStream('mt19937ar','Seed','shuffle')
%%%reset(RandStream.getGlobalStream,sum(100*clock))
%%%%%%Create a random number stream using a generator seed based on the current time.
%%%%%%It is usually not desirable to do this more than once per MATLAB session as it may affect the statistical properties of the random numbers MATLAB produces.
%%%%%%%%We do this because the compiled app sets all the random number stream to the same, as it's running on different servers. Then the servers hop to each folder at the same time, which is not what we want.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Toolbox Check (Sims can run without the Parallel Toolbox)
[workers,parallel_flag]=check_parallel_toolbox(app,parallel_flag);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Check for the Number of Folders to Sim
[sim_number,folder_names,num_folders]=check_rev_folders(app,rev_folder);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%If we have it, start the parpool.
disp_progress(app,strcat(rev_folder,'--> Starting Parallel Workers . . . [This usually takes a little time]'))
tic;
[poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
toc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Load all the mat files in the main folder
[reliability]=load_data_reliability(app);
[confidence]=load_data_confidence(app);
[FreqMHz]=load_data_FreqMHz(app);
[Tpol]=load_data_Tpol(app);
[building_loss]=load_data_building_loss(app);
[mc_percentile]=load_data_mc_percentile(app);
[mc_size]=load_data_mc_size(app);
[sim_radius_km]=load_data_sim_radius_km(app);
[array_bs_eirp_reductions]=load_data_array_bs_eirp_reductions(app);
[norm_aas_zero_elevation_data]=load_data_norm_aas_zero_elevation_data(app);
[tf_opt]=load_data_tf_opt(app);
[deployment_percentage]=load_data_deployment_percentage(app);
[tf_clutter]=load_data_tf_clutter(app);
server_status_rev2(app,tf_server_status)
move_list_reliability=reliability;
load('array_bs_eirp.mat','array_bs_eirp')



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Step 1: Propagation Loss (ITM)
string_prop_model='ITM'
tf_recalc_pathloss=0;
part1_calc_pathloss_clutter2108_rev10(app,rev_folder,folder_names,parallel_flag,sim_number,reliability,confidence,FreqMHz,Tpol,workers,string_prop_model,tf_recalc_pathloss,tf_server_status,tf_clutter)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Step 2: Move List with the different EIRP levels. (Graphics and Excel Later)
part2_movelist_calculation_multi_eirp(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,array_bs_eirp,array_bs_eirp_reductions,tf_recalculate,tf_opt)




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Next Step: Export the Excel Spreadsheets with the Link Budget Calculations
'Next step: Excel Write the Link Budget Data'




end_clock=clock;
total_clock=end_clock-top_start_clock;
total_seconds=total_clock(6)+total_clock(5)*60+total_clock(4)*3600+total_clock(3)*86400;
total_mins=total_seconds/60;
total_hours=total_mins/60;
if total_hours>1
    strcat('Total Hours:',num2str(total_hours))
elseif total_mins>1
    strcat('Total Minutes:',num2str(total_mins))
else
    strcat('Total Seconds:',num2str(total_seconds))
end

'Go run the simulation'