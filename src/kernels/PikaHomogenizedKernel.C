/**********************************************************************************/
/*                  Pika: Phase field snow micro-structure model                  */
/*                                                                                */
/*                     (C) 2014 Battelle Energy Alliance, LLC                     */
/*                              ALL RIGHTS RESERVED                               */
/*                                                                                */
/*                   Prepared by Battelle Energy Alliance, LLC                    */
/*                      Under Contract No. DE-AC07-05ID14517                      */
/*                      With the U. S. Department of Energy                       */
/**********************************************************************************/
#include "PikaHomogenizedKernel.h"

registerMooseObject("PikaApp", PikaHomogenizedKernel);

template<>
InputParameters validParams<PikaHomogenizedKernel>()
{
  InputParameters params = validParams<HomogenizedHeatConduction>();
  params += validParams<CoefficientKernelInterface>();
  return params;
}


PikaHomogenizedKernel::PikaHomogenizedKernel(const InputParameters & parameters):
  HomogenizedHeatConduction(parameters),
  CoefficientKernelInterface(parameters)
{
}

Real
PikaHomogenizedKernel::computeQpResidual()
{
  return coefficient(_qp) * HomogenizedHeatConduction::computeQpResidual();
}
