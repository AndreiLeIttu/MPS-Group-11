% ==================================================
% 1. DATA IMPORT & ENUM DECLARATIONS
% ==================================================
% The .dzn file will populate these sets automatically
enum Suppliers;
enum SupplierDocks;
enum Plants;
enum PlantDocks;
enum Products;
enum StackCodes;

% --- GLOBAL PARAMETERS ---
int: coefficient_inventory_cost;        % alpha^I
int: coefficient_transportation_cost;   % alpha^T
float: coefficient_cost_extra_truck;    % alpha^E
int: timelimit_sec;

% ==================================================
% 2. ITEM PARAMETERS (Inputs)
% ==================================================
int: n_input_items;
set of int: ITEMS = 1..n_input_items;

array[ITEMS] of string: item_ident;
array[ITEMS] of Suppliers: item_supplier;       % IU_i
array[ITEMS] of SupplierDocks: item_supplier_dock; 
array[ITEMS] of Plants: item_plant;             % IP_i
array[ITEMS] of PlantDocks: item_plant_dock;    % IG_i
array[ITEMS] of Products: item_product;         % IR_i
array[ITEMS] of string: item_package;
array[ITEMS] of int: item_length;               % IL_i
array[ITEMS] of int: item_width;                % IW_i
array[ITEMS] of int: item_height;               % IH_i
array[ITEMS] of float: item_weight;             % IM_i
array[ITEMS] of int: item_nesting_height;       % Hat_IH_i
array[ITEMS] of StackCodes: item_stack_code;    % IS_i
array[ITEMS] of string: item_forced_orientation;% IO_i
array[ITEMS] of int: item_earliest;             % IDE_i
array[ITEMS] of int: item_latest;               % IDL_i
array[ITEMS] of int: item_inventory_cost;       % IC_i
array[ITEMS] of int: item_max_stack;            % ISM_i

% ==================================================
% 3. TRUCK PARAMETERS (Inputs)
% ==================================================
int: n_input_trucks;
set of int: TRUCKS = 1..n_input_trucks;

array[TRUCKS] of string: truck_id;
array[TRUCKS] of int: truck_arrival;            % TDA_t
array[TRUCKS] of set of Suppliers: truck_supplier_code; % TU_t
array[TRUCKS] of set of int: truck_supplier_loading_order;
array[TRUCKS] of set of SupplierDocks: truck_supplier_dock;
array[TRUCKS] of set of int: truck_supplier_dock_loading_order;
array[TRUCKS] of set of int: truck_plant_dock_loading_order;
array[TRUCKS] of set of PlantDocks: truck_plant_dock;
array[TRUCKS] of set of Products: truck_product_code;   % TR_t
array[TRUCKS] of Plants: truck_plant_code;      % TP_t
array[TRUCKS] of int: truck_max_weight;         % TM_t^m
array[TRUCKS] of int: truck_max_density;        % TEM_t
array[TRUCKS] of float: truck_cost;             % TC_t
array[TRUCKS] of int: truck_stack_with_multiple_docks; % TF_t
array[TRUCKS] of int: truck_is_extra;           % 0 = Planned, 1 = Extra
array[TRUCKS] of int: truck_length;
array[TRUCKS] of int: truck_width;
array[TRUCKS] of int: truck_height;
array[TRUCKS] of int: truck_max_weight_on_the_bottom_item_in_stacks;
array[TRUCKS] of int: truck_emmm;
array[TRUCKS] of int: truck_emmr;
array[TRUCKS] of int: truck_cm;
array[TRUCKS] of int: truck_cjfm;
array[TRUCKS] of int: truck_cjfc;
array[TRUCKS] of int: truck_cjfh;
array[TRUCKS] of int: truck_em;
array[TRUCKS] of int: truck_ejhr;
array[TRUCKS] of int: truck_ejcr;
array[TRUCKS] of int: truck_ejeh;

% ==================================================
% 4. DECISION VARIABLES
% ==================================================

% Main Decision: Which truck carries item i?
array[ITEMS] of var TRUCKS: assigned_truck;

% Helper: Is truck t used? (1 if yes, 0 if no)
array[TRUCKS] of var 0..1: truck_is_used;

% Link the helper variable
constraint forall(t in TRUCKS)(
    truck_is_used[t] = bool2int(exists(i in ITEMS)(assigned_truck[i] == t))
);

