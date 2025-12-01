% ==================================================
% 1. DATA IMPORT & ENUM DECLARATIONS
% ==================================================
% The .dzn file will populate these sets automatically

include "globals.mzn";

% list of suppliers
enum Suppliers;     
% list of supplier docks
enum SupplierDocks; 
% list of plants
enum Plants;        
% list of plant docks
enum PlantDocks;    
% list of products
enum Products;      
% list of stack codes
enum StackCodes;    

% --- GLOBAL PARAMETERS ---
% alpha^I: coefficient of inventory cost in the objective function
int: coefficient_inventory_cost;      
% alpha^T: coefficient of transportation cost in the objective function
int: coefficient_transportation_cost; 
% alpha^E: coefficient of cost for extra trucks
float: coefficient_cost_extra_truck;  
% time limit
int: timelimit_sec;                   

% ==================================================
% 2. ITEM PARAMETERS (Inputs)
% ==================================================
% number of items  i
int: n_input_items;                   
% index set for the items i
set of int: ITEMS = 1..n_input_items; 

% item i
array[ITEMS] of string: item_ident;                
% IU_i: supplier of item i
array[ITEMS] of Suppliers: item_supplier;          
% IK_i: supplier dock of item i
array[ITEMS] of SupplierDocks: item_supplier_dock; 
% IP_i: destination plant of item i
array[ITEMS] of Plants: item_plant;                
% IG_i: plant dock of item i
array[ITEMS] of PlantDocks: item_plant_dock;       
% IR_i: product of item i
array[ITEMS] of Products: item_product;            
% type of package
array[ITEMS] of string: item_package;              
% IL_i: length of item i
array[ITEMS] of int: item_length;                  
% IW_i: width of item i
array[ITEMS] of int: item_width;                   
% IH_i: height of item i
array[ITEMS] of int: item_height;                  
% Hat_IH_i: nesting height of item i
array[ITEMS] of int: item_nesting_height;          
% IM_i: weight of item i
array[ITEMS] of float: item_weight;                
% IS_i: stackability code of item i
array[ITEMS] of StackCodes: item_stack_code;       
% IO_i: forced orientation of item i
array[ITEMS] of string: item_forced_orientation;   
% IDE_i: earliest arrival time of item i
array[ITEMS] of int: item_earliest;                
% IDL_i: latest arrival time of item i
array[ITEMS] of int: item_latest;                  
% IC_i: inventory cost of item i
array[ITEMS] of int: item_inventory_cost;          
% ISM_i: maximal stackability of item i
array[ITEMS] of int: item_max_stack;               

% ==================================================
% 3. TRUCK PARAMETERS (Inputs)
% ==================================================
% number of trucks
int: n_input_trucks;                    
% index set for the trucks
set of int: TRUCKS = 1..n_input_trucks; 

% truck t
array[TRUCKS] of string: truck_id;                                   
% TDA_t: arrival time of truck t at TP_t
array[TRUCKS] of int: truck_arrival;                                 
% TU_t: set of candidate suppliers picked-up by truck t
array[TRUCKS] of set of Suppliers: truck_supplier_code;              
% TE_t: supplier loading order for truck t : it is a list indexed by the elements of TU_t containing for each supplier its loading order
array[TRUCKS] of set of int: truck_supplier_loading_order;           
% TK_ut: set of candidate supplier docks k of supplier u loaded into truck t
array[TRUCKS] of set of SupplierDocks: truck_supplier_dock;          
% TKE_ut: dock loading order of supplier u for truck t : it is a list indexed by the elements of TK_ut containing for each supplier dock its loading order
array[TRUCKS] of set of int: truck_supplier_dock_loading_order;      
% TGE_pt: dock loading order of plant p for truck t : it is a list indexed by the elements of TG_pt containing for each plant dock its loading order
array[TRUCKS] of set of int: truck_plant_dock_loading_order;         
% TG_pt: set of candidate plant docks g of plant p delivered by truck t
array[TRUCKS] of set of PlantDocks: truck_plant_dock;                
% TR_t: set of candidate products picked-up by truck t
array[TRUCKS] of set of Products: truck_product_code;                
% TP_t: destination plant of truck t
array[TRUCKS] of Plants: truck_plant_code;                           
% TM^m_t: max authorized loading weight of truck t
array[TRUCKS] of int: truck_max_weight;                              
% TEM_t: maximal density of stacks in truck t
array[TRUCKS] of int: truck_max_density;                             
% TC_t: cost of truck t
array[TRUCKS] of float: truck_cost;                                  
% TF_t: flag "stack with multiple docks" for truck t
array[TRUCKS] of 0..1: truck_stack_with_multiple_docks;              
% 0 = Planned, 1 = Extra
array[TRUCKS] of int: truck_is_extra;                                
% TL_t: length of truck t
array[TRUCKS] of int: truck_length;                                  
% TW_t: width of truck t
array[TRUCKS] of int: truck_width;                                   
% TH_t: height of truck t
array[TRUCKS] of int: truck_height;                                  
% TMM_ty: maximal total weight of all the items packed above the bottom item associated with product y in any stack of truck t
array[TRUCKS] of int: truck_max_weight_on_the_bottom_item_in_stacks; 
% EM_mm: max weight on the middle axle of the trailer
array[TRUCKS] of int: truck_emmm;                                    
% EM_mr: max weight on the rear axle of the trailer
array[TRUCKS] of int: truck_emmr;                                    
% CM: weight of the tractor
array[TRUCKS] of int: truck_cm;                                      
% CJ_fm: distance between the front and middle axles of the tractor
array[TRUCKS] of int: truck_cjfm;                                    
% CJ_fc: distance between the front axle and the center of gravity of the tractor
array[TRUCKS] of int: truck_cjfc;                                    
% CJ_fh: distance between the front axle and the harness of the tractor
array[TRUCKS] of int: truck_cjfh;                                    
% EM: weight of the empty trailer
array[TRUCKS] of int: truck_em;                                      
% EJ_hr: distance between the harness and the rear axle of the trailer
array[TRUCKS] of int: truck_ejhr;                                    
% EJ_cr: distance between the center of gravity of the trailer and the rear axle
array[TRUCKS] of int: truck_ejcr;                                    
% EJ_eh: distance between the start of the trailer and the harness
array[TRUCKS] of int: truck_ejeh;                                    

% ==================================================
% 4. DECISION VARIABLES
% ==================================================

% Main Decision: Which truck carries item i?
array[ITEMS] of var TRUCKS: assigned_truck; 
% Helper: Is truck t used? (1 if yes, 0 if no)
array[TRUCKS] of var 0..1: truck_is_used; 

% Maximum number of stacks
int: max_stacks = n_input_items; 
% Number of stacks
var 1..max_stacks: stacks; 
% Set of stacks
set of int: stack_set = 1..max_stacks; 

% Which truck each stack belongs to
array[stack_set] of var TRUCKS: stack_to_truck; 
% Which stack each item belongs to
array[ITEMS] of var 1..max_stacks: assigned_stack; 

% These two decision variables were part of our initial modelling approach. We used them to model constraints I3 (truck compatible with product) and I4 (truck stops by the supplier).
% truck_can_pickup_item[t, i]: true if truck t is allowed to pickup item i, false otherwise
% truck_compatible_supplier[t, i]: true if truck t is compatible with the supplier of item i, false otherwise
% We realized that we can reduce the complexity of our model by using the assigned_truck decision variable, so these two turned became redundant.
% Hence, by removing them we improved our model and made it easier to understand.
% array[TRUCKS, ITEMS] of var bool: truck_can_pickup_item;
% array[TRUCKS, ITEMS] of var bool: truck_compatible_supplier;

% ==================================================
% 5. CONSTRAINTS
% ==================================================

% Symmetry Breaking (Essential)
constraint value_precede_chain(1..n_input_items, assigned_stack);

% Link the helper variable
constraint forall(t in TRUCKS)(
    truck_is_used[t] = bool2int(exists(i in ITEMS)(assigned_truck[i] == t))
);

% ITEM CONSTRAINS:
% I1 & I2
constraint forall(i in ITEMS)(
  % The assigned stack must be valid
  assigned_stack[i] <= stacks /\                           
  % The truck an item is assigned to, should be the same as the truck to which its stack is assigned to.
  assigned_truck[i] = stack_to_truck[assigned_stack[i]] /\ 
  % The item i must be assigned to a truck which holds the same plant code.
  item_plant[i] = truck_plant_code[assigned_truck[i]]      
);

% These are the old versions of our I3 and I4 constraints. 
%I3
% constraint forall(t in TRUCKS, i in ITEMS) (
%   if item_product[i] in truck_product_code[t] then
%     truck_can_pickup_item[t, i] = true
%   else
%     truck_can_pickup_item[t, i] = false
%   endif
% );
% %I4
% constraint forall(t in TRUCKS, i in ITEMS) (
%   if item_supplier[i] in truck_supplier_code[t] then
%     truck_compatible_supplier[t, i] = true
%   else
%     truck_compatible_supplier[t, i] = false
%   endif
% );

%I3
% If a product is not in a truck's product codes, then it is not allowed to be assigned to that truck
constraint forall(t in TRUCKS, i in ITEMS) (
  if not (item_product[i] in truck_product_code[t]) then
    assigned_truck[i] != t 
  endif
);

%I4
% If an item supplier is not in a truck's supsplier codes, then it is not allowed to be assigned to that truck
constraint forall(t in TRUCKS, i in ITEMS) (
  if not (item_supplier[i] in truck_supplier_code[t]) then
    assigned_truck[i] != t 
  endif
);

%I5
% The truck must arrive within the item's specific time window
constraint forall(i in ITEMS)(
    truck_arrival[assigned_truck[i]] >= item_earliest[i] 
    /\ 
    truck_arrival[assigned_truck[i]] <= item_latest[i]
);

% Link item assignment to stack assignment
constraint forall(i in ITEMS)(
    assigned_truck[i] == stack_to_truck[assigned_stack[i]]
);

% STACK CONSTRAINTS:
% ignore unused stacks 
constraint forall(s in stack_set where s > stacks) (
  forall(i in ITEMS) (assigned_stack[i] != s)
);

%S1: 
% Each item from a stack s should have the same supplier, plant, supplier dock and stack code
constraint forall(s in stack_set where s <= stacks) (
  forall(i,j in ITEMS where assigned_stack[i] = s /\ assigned_stack[j] = assigned_stack[i]) (
    item_supplier[i] = item_supplier[j] /\
    item_plant[i] = item_plant[j] /\
    item_supplier_dock[i] = item_supplier_dock[j] /\ 
    item_stack_code[i] = item_stack_code[j]
  )
);

%S2: 
% if the TF_t flag is set to false, then all items in a stack must have the same plant dock
constraint forall(t in TRUCKS) (
  truck_stack_with_multiple_docks[t] = 0 ->  forall(s in stack_set where stack_to_truck[s] = t) (
    forall (i, j in ITEMS where assigned_stack[i] = s /\ assigned_stack[j] = assigned_stack[i])(
      item_plant_dock[i] = item_plant_dock[j]
    )
  )
);

%S4:
% If two items have a different orientation, then they should not be in the same stack
constraint forall(i, j in ITEMS where i<j) (
  item_forced_orientation[i] != item_forced_orientation[j] -> assigned_stack[i] != assigned_stack[j] 
);

%S6:
% The number of items in a stack needs to be less than or equal to the minimum stackability of the items in that stack
constraint forall(s in stack_set) (
  let {
    var int: count_items_in_stack = sum(i in ITEMS) (assigned_stack[i] = s), % number of items which were assigned to stack s
   } 
  in 
    count_items_in_stack > 0 -> count_items_in_stack <= min([item_max_stack[i] | i in ITEMS where assigned_stack[i] = s])
    % if stack s contains more than 0 items, enforce the condition described above
);

% WEIGHT CONSTRAINT:
%W1
% The total weight of the items from a truck should not exceed the truck's max weight
constraint forall(t in TRUCKS)(
  sum(i in ITEMS where assigned_truck[i]==t)(item_weight[i])
  <= truck_max_weight[t]
);

% ==================================================
% 6. OBJECTIVE FUNCTION
% ==================================================

% Total transportation cost for the used trucks
var float: total_transport_cost = sum (t in TRUCKS) (truck_cost[t]*truck_is_used[t]);

var float: total_inventory_cost = sum(i in ITEMS)(
    item_inventory_cost[i] * ( 
        (item_latest[i] - truck_arrival[assigned_truck[i]]) / 1440.0 
    ));

var float: total_cost = 
    (coefficient_transportation_cost * total_transport_cost) + 
    (coefficient_inventory_cost * total_inventory_cost);
    
solve minimize total_cost;

% ==================================================
% 7. OUTPUT FORMATTING
% ==================================================

output [
  "\n=== 1. STACKS ===\n",
  "Stack_ID, Truck_ID, Stack_Code\n"
] ++
[
  % INLINE CALCULATION: Check if stack 's' has any items
  if sum(i in ITEMS)(bool2int(fix(assigned_stack[i]) == s)) > 0 then
    show(s) ++ ", " ++ 
    show(truck_id[fix(stack_to_truck[s])]) ++ ", " ++
    % Find the first item in this stack to get the Stack Code (since all must match)
    show(item_stack_code[min([i | i in ITEMS where fix(assigned_stack[i]) == s])]) ++ "\n"
  else "" endif
  | s in stack_set
];

output [
  "\n=== 2. ITEMS ===\n",
  "Item_ID, Truck_ID, Stack_ID, Product_Code\n"
] ++
[
  show(item_ident[i]) ++ ", " ++
  show(truck_id[fix(assigned_truck[i])]) ++ ", " ++
  show(assigned_stack[i]) ++ ", " ++
  show(item_product[i]) ++ "\n"
  | i in ITEMS
];

output [
  "\n=== 3. TRUCKS ===\n",
  "Truck_ID, Time_Offset_Minutes, Used, Total_Weight, Max_Weight\n"
] ++
[
  if fix(truck_is_used[t]) == 1 then
    show(truck_id[t]) ++ ", " ++
    show(truck_arrival[t]) ++ ", " ++ 
    "YES, " ++
    show(sum(i in ITEMS where fix(assigned_truck[i]) == t)(item_weight[i])) ++ ", " ++
    show(truck_max_weight[t]) ++ "\n"
  else "" endif
  | t in TRUCKS
];

output [
  "\n=== SUMMARY ===\n",
  "Total Cost: " ++ show(total_cost) ++ "\n",
  "Transportation Cost: " ++ show(total_transport_cost) ++ "\n",
  "Inventory Cost: " ++ show(total_inventory_cost) ++ "\n"
];
