import numpy as np
import pandas as pd
from Forest import Forest


class RFSampler:

	def __init__(self,components,nclasses=2,class_dist=np.array([]),p=0):
		


		'''
		Grow the Forest and store the leaves to compute a function to label the points
		'''

		self.components = map(np.array,components)
		self.p = p
		self.num_components = len(components)
		self.num_nodes = np.array(map(np.prod,components)) + 1 
		self.num_vars = map(len,components)
		self.n = sum(self.num_vars)

		self.forest = Forest(components)
		self.leaves = self.forest.get_leaves()
		self.nleaves = len(self.leaves)
		
		self.cardinalities = np.concatenate([self.components])[0]

		if len(class_dist) == 0:
			self.nclasses = nclasses
			self.classes = ['C%d'%(x) for x in np.arange(1,self.nclasses+1)]
			self.class_dist = class_dist

		else:
			self.class_dist=np.array(class_dist)
			self.nclasses = len(self.class_dist)
			self.classes = ['C%d'%(x) for x in np.arange(1,self.nclasses+1)]
			self.class_limit = np.floor(self.class_dist * self.nleaves)



		'''
		Assign leaves to classes
		
		Currently:
			(1) deterministically switching the classes of the leaves 
			(2) Any number of classes (provided the number is less than the number of leaves)
		'''

		self.label_function = {}
		if len(self.class_dist) == 0:
			counter = 1

			for leaf in self.leaves:
				self.label_function[leaf] = self.classes[np.mod(counter,self.nclasses)]
				counter = counter + 1
		
		else:
			self.class_counts = np.zeros(self.nclasses)
			counter = 0

			for leaf in self.leaves:
				if self.class_counts[ np.mod(counter,self.nclasses)  ] < self.class_limit[np.mod(counter,self.nclasses)]:
					self.label_function[leaf] = self.classes[np.mod(counter,self.nclasses)]
					self.class_counts[np.mod(counter,self.nclasses) ] += 1 
					counter = counter + 1
				else:
					possible_labels, = np.where(self.class_counts < self.class_limit) 
					possible_labels = possible_labels+1
					if(len(possible_labels)>0):
						alternative_label = np.random.choice(possible_labels)
						self.label_function[leaf] = 'C%d'%alternative_label
						self.class_counts[alternative_label-1] += 1 
					else:
						self.label_function[leaf]='C1'
						self.class_counts[0] += 1
					counter = counter + 1


			




	'''
	Method to generate a sample based on the tree
	'''

	def get_sample(self,N,filename):	
		col_names = ['A%d'%(x) for x in np.arange(1,self.n+2)]
		sim_result = pd.DataFrame(index = np.arange(N),columns=col_names)

		for sample_num in np.arange(N):
			
			var_index = 0
			old_value = 0 

			for comp_index in np.arange(self.num_components):

				curr_component = self.forest.get_tree(comp_index)

				new_value = np.random.choice(curr_component[self.forest.roots[comp_index]])
				var_index = var_index + 1 if var_index > 0 else 0
				sim_result.ix[sample_num, var_index  ] = new_value
				old_value = new_value

				
				for i in np.arange(1,self.num_vars[comp_index]):
					var_index = var_index + 1
					new_value = np.random.choice(curr_component[old_value])
					sim_result.ix[sample_num,var_index] = (new_value - (np.sum([np.prod(self.cardinalities[:j]) for j in np.arange(var_index-1)]) +1)) % self.cardinalities[var_index] + 1
					old_value = new_value
			if(np.random.random() < self.p ):
				other_classes = list(set(self.classes) - set(self.label_function[new_value]))
				sim_result.ix[sample_num,self.n] = np.random.choice( other_classes )
			else:
				sim_result.ix[sample_num,self.n] = self.label_function[new_value] 

		sim_result.to_csv(filename,index=False)

