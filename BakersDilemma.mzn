enum NAME;
array[NAME] of int: available_funds;

enum INGREDIENT;
array[INGREDIENT] of float: ingredient_costs;
array[INGREDIENT] of int: required_ingredient_quantities;

enum MATCHING = { none, partial, full };
array[NAME] of var MATCHING: matching_requirement;

array[NAME,INGREDIENT] of float: fund_upper_bounds;

array[NAME,INGREDIENT] of var int: contributions;

%define intermediary variable totals
%and make sure totals are bounded by available funds of each funder
array[NAME] of var int: totals;
constraint forall( n in NAME )
                 ( sum( i in INGREDIENT )
                      ( contributions[n,i] )
                   = totals[n] );
constraint forall( n in NAME )( totals[n] <= available_funds[n] );

%apply upper bounds on contributions of each funder to each ingredient
constraint forall( n in NAME, i in INGREDIENT )
                 ( contributions[n,i] <= fund_upper_bounds[n,i] /\
                   contributions[n,i] >= 0);

%make sure each ingredient is paid for in full
constraint forall( i in INGREDIENT )
                 ( sum( n in NAME )
                      ( contributions[n,i] ) =
                         ingredient_costs[i] * required_ingredient_quantities[i] );
                         
%apply matching requirement constraints
constraint forall( i in INGREDIENT, n in NAME )
           ( (matching_requirement[n] == partial ->
             exists(m in NAME where m!=n)(contributions[m,i]>0)) /\
             (matching_requirement[n] == full /\
             contributions[n,i]>0 ->
             exists(m in NAME where m!=n)
             (contributions[m,i]=contributions[n,i])) );

%punish contributers who put matching restrictions on their funds
%this punishment is weighted: funders with stricter matching restrictions
%are given a higher weight in this punishment maximization
var int: obj;
constraint obj = sum( n in NAME, i in INGREDIENT )( contributions[n,i] );
solve maximize sum( n in NAME )
( matching_requirement[n]*totals[n] );

%output name of contributer, followed by amounts towards each ingredient,
%in the order in which they appear in the data file.
%finishes the line with a cumulative total of all investments by contributor.
output
[if i = 1 then "\(n): " else "" endif ++
show(contributions[n,i]) ++
if i < card(INGREDIENT) then ", "
else " tot: " ++ show(totals[n]) ++ "\n" endif
| n in NAME, i in INGREDIENT ];