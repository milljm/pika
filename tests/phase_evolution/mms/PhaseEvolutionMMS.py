'''***************************************
   * Generating Method of MFG-ed         *
   * Solutions applied to the Phase      *
   * Evolution eq. (33) in Kaempfer 2009 *
   *                                     *
   * Compile:                            *
   * python PhaseEvolutionMMS.py         *
   *                                     *
   ***************************************'''

#!/usr/bin/python
                                 
from sympy import *
from sympy.utilities.codegen import codegen
init_printing()

x = symbols('x')
y = symbols('y')
t = symbols('t')

#auxVariables
<<<<<<< HEAD
u = sin(4*x*y) 
T=100.0*(x*y)
=======
<<<<<<< HEAD
u = 0.5*sin(4.0*x*y) 
T=-10*(x*y)+273
=======
u = sin(4*x*y) 
T=100.0*(x*y)
>>>>>>> 3fbfd84f8fad91aea639a1611852e440ccd7de63
>>>>>>> 4615a920e98284e4192a2f6796205b222b7c25da
#variables
phi = t*sin(4.0*pi*x)*sin(4.0*pi*y)

print '\n'
print 'T =\n '
pprint(T)
print '\n'

print '\n'
print 'U =\n '
pprint(u)
print '\n'

print '\n'
print 'phi =\n '
pprint(phi)
print '\n'


#Interface thicknesss
w = symbols('w')
#phase relaxtation time constant
tau = symbols('tau')

#phase coupling constant related to capillary length
lam = symbols('lambda')

#Gas Constants
R_da = symbols('R_da')
R_v = symbols('R_v')

#Air
P_a = symbols('P_a')
rho_a = symbols('rho_a')

#Ice
rho_i = symbols('rho_i')

#Saturated Vapor Density at Reference Temp.
T_o =263 #[K] or -10 C
K_fit = [-0.58653696e4, 0.2224103300e2, 0.13749042e-1, -0.34031775e-4, 0.26967687e-7, 0.6918651]

P_vs_o = exp(K_fit[0]*T_o**(-1.0) + K_fit[1]*T_o**0.0 + K_fit[2]*T_o**1.0 + K_fit[3]*T_o**2.0 + K_fit[4]*T_o**3.0 + K_fit[5]*log(T_o))
x_s_o = (R_da/R_v)*(P_vs_o/(P_a-P_vs_o))

rho_vs_o = rho_a * x_s_o

#Chemical equivalent
P_vs = exp(K_fit[0]*T**(-1.0) + K_fit[1]*T**0.0 + K_fit[2]*T**1.0 + K_fit[3]*T**2.0 + K_fit[4]*T**3.0 + K_fit[5]*log(T))
x_s = (R_da/R_v)*(P_vs/(P_a-P_vs))
rho_vs = rho_a * x_s

u_eq = (rho_vs-rho_vs_o)/rho_i
<<<<<<< HEAD

=======
<<<<<<< HEAD
print('\n')
print('evaluated = \n')
print(u_eq.evalf(subs={x:1.0, y:1.0, t:1.0, rho_a:1.341, rho_i:918.9, P_a:101325}))
=======

>>>>>>> 3fbfd84f8fad91aea639a1611852e440ccd7de63
>>>>>>> 4615a920e98284e4192a2f6796205b222b7c25da
#Simplifying Math terms
grad_phi = [diff(phi,x), diff(phi,y)]

lapl_phi = diff(grad_phi[0],x) + diff(grad_phi[1],y)

dPhi_dt = diff(phi,t)

#Equation 33:

#Phi time derivative
term1 = tau*dPhi_dt

#Square of the gradient
term2 = (w**2.0) * lapl_phi

#Double well potential
term3 = phi-(phi*phi*phi)

#Phase Potential
term4 = lam*(u-u_eq)*(1.0-phi*phi)**2.0

<<<<<<< HEAD
# Eq. (33) 
phase_evol = term1-term2-term3-term4

#Generate the C/C++ version of the code.
[(c_name, c_code), (h_name, c_header)] = codegen(
     ("f", phase_evol), "C", "test", header=False, empty=False)
print(c_code)


print('\n')
pprint(phase_evol)
=======
<<<<<<< HEAD
# Eq. (33) wihtout potential 
phase_evol = term1-term2-term3
# Eq. (33) 
#phase_evol = term1-term2-term3-term4

#Generate the C/C++ version of the code.
print('\n')
[(c_name, c_code), (h_name, c_header)] = codegen(
     ("f", phase_evol), "C", "test", header=False, empty=False)
print(c_code)
print('\n')


#Generate C/C++ code for term 4
[(c_name, c_code), (h_name, c_header)] = codegen(
     ("f", term4), "C", "test", header=False, empty=False)
print(c_code)
print('\n')
=======
# Eq. (33) 
phase_evol = term1-term2-term3-term4

#Generate the C/C++ version of the code.
[(c_name, c_code), (h_name, c_header)] = codegen(
     ("f", phase_evol), "C", "test", header=False, empty=False)
print(c_code)
>>>>>>> 3fbfd84f8fad91aea639a1611852e440ccd7de63
>>>>>>> 4615a920e98284e4192a2f6796205b222b7c25da
