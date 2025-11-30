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
array[TRUCKS] of 0..1: truck_stack_with_multiple_docks; % TF_t
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


array[TRUCKS, ITEMS] of var bool: truck_can_pickup_item;
array[TRUCKS, ITEMS] of var bool: truck_compatible_supplier;

int: max_stacks = 1000000;
var 1..max_stacks: stacks;
set of int: stack_set = 1..max_stacks;

array[stack_set] of var TRUCKS: stack_to_truck;

array[ITEMS] of var 1..max_stacks: assigned_stack;


%ITEM CONSTRAINTS
constraint forall(i in ITEMS)(
  assigned_stack[i] <= stacks /\                              %I1
  assigned_truck[i] = stack_to_truck[assigned_stack[i]] /\    %I1
  item_plant[i] = truck_plant_code[assigned_truck[i]]         %I2
);

%I3:
constraint forall(t in TRUCKS, i in ITEMS) (
  if item_product[i] in truck_product_code[t] then
    truck_can_pickup_item[t, i] = true
  else
    truck_can_pickup_item[t, i] = false
  endif
);

%I4:
constraint forall(t in TRUCKS, i in ITEMS) (
  if item_supplier[i] in truck_supplier_code[t] then
    truck_compatible_supplier[t, i] = true
  else
    truck_compatible_supplier[t, i] = false
  endif
);

%I5
constraint forall(i in ITEMS)(
    truck_arrival[assigned_truck[i]] >= item_earliest[i] 
    /\ 
    truck_arrival[assigned_truck[i]] <= item_latest[i]
);

% Link item assignment to stack assignment
constraint forall(i in ITEMS)(
    assigned_truck[i] == stack_to_truck[assigned_stack[i]]
);

%ignore unused stacks 
constraint forall(s in stack_set where s > stacks) (
  forall(i in ITEMS) (assigned_stack[i] != s)
);

constraint forall(s in stack_set where s <= stacks) (
  forall(i,j in ITEMS where assigned_stack[i] = s /\ assigned_stack[j] = assigned_stack[i]) (
    item_supplier[i] = item_supplier[j] /\
    item_plant[i] = item_plant[j] /\
    item_supplier_dock[i] = item_supplier_dock[j] /\ 
    item_stack_code[i] = item_stack_code[j]
  )
);

constraint forall(t in TRUCKS) (
  truck_stack_with_multiple_docks[t] = 0 ->  forall(s in stack_set where stack_to_truck[s] = t) (
    forall (i, j in ITEMS where assigned_stack[i] = s /\ assigned_stack[j] = assigned_stack[i])(
      item_plant_dock[i] = item_plant_dock[j]
    )
  )
);


constraint forall(t in TRUCKS)(
sum(i in ITEMS where assigned_truck[i]==t)(item_weight[i])
<= truck_max_weight[t]
);  %W1 constraint








