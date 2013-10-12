import numpy as np
from Forest import Forest

class RFSampler:

	def __init__(self,components,p=0):

		self.components = map(np.array,components)
		self.p = p
		self.num_components = len(components)
		self.num_nodes = np.array(map(np.prod,components)) + 1 
		self.num_vars = map(len,components)
		self.n = sum(self.num_vars)

		self.cardinalities = np.concatenate([self.components])[0]

		'''
		Grow the Forest and store the leaves to compute a function to label the points
		'''

		self.forest = Forest(components)
		self.leaves = self.forest.get_leaves()

		'''
		Assign leaves to classes
		
		Currently:
			(1) deterministically switching the classes of the leaves
			(2) binary classes

		Both will be changed
		'''

		self.label_function = {}

		counter = 0

		for leaf in self.leaves:
				if counter % 2 == 0:
					self.label_function[leaf] = 1
					counter = counter + 1
				else:
					self.label_function[leaf] = 2
					counter = counter + 1


	'''
	Method to generate a sample based on the tree
	'''

	def get_sample(self,N,filename):	
		sim_result = np.zeros((N,self.n+1))
		for sample_num in np.arange(N):
			
			var_index = 0
			old_value = 0 

			for comp_index in np.arange(self.num_components):

				curr_component = self.forest.get_tree(comp_index)

				new_value = np.random.choice(curr_component[self.forest.roots[comp_index]])
				var_index = var_index + 1 if var_index > 0 else 0
				sim_result[sample_num, var_index  ] = new_value
				old_value = new_value

				
				for i in np.arange(1,self.num_vars[comp_index]):
					var_index = var_index + 1
					new_value = np.random.choice(curr_component[old_value])
					sim_result[sample_num,var_index] = (new_value - (np.sum([np.prod(self.cardinalities[:j]) for j in np.arange(var_index-1)]) +1)) % self.cardinalities[var_index] + 1
					old_value = new_value
			if(np.random.random() < self.p ):
				if self.label_function[new_value] == 1.0:
					sim_result[sample_num,self.n] = 2.0
				else:
					sim_result[sample_num,self.n] = 1.0
			else:
				sim_result[sample_num,self.n] = self.label_function[new_value] 
		np.savetxt(filename, sim_result,delimiter=',')

