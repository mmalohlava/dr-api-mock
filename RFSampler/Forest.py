import numpy as np

class Forest:

	def __init__(self,cardinalities):
		self.cardinalities = map(np.array,cardinalities)
		self.num_components = len(cardinalities)
		self.num_nodes = np.array(map(np.prod,self.cardinalities)) + 1 


		self.trees = {}
		'''
		Adjacency List representation of a tree
		'''
		max_state = 0

		for tree in np.arange(0,self.num_components):
			n = self.num_nodes[tree] 
			cards = list(self.cardinalities[tree])

			
			self.trees[tree] = {}
			parents = [max_state]
			
			while(len(cards)>0):
				curr_var_card = cards.pop(0)
				next_parents = []
				while(len(parents)>0):
					parent = parents.pop(0) 
					self.trees[tree][parent] = np.arange(curr_var_card) + 1 + max_state
					next_parents = next_parents + list(self.trees[tree][parent])
					max_state = max_state + curr_var_card
				parents = next_parents
			max_state = max_state + 1

		self.roots = [] 

		for i in range(self.num_components):
			self.roots.append(min(self.trees[i].keys()))



	def get_num_trees(self):
		return(self.num_components)

	def get_tree(self, i):
		return(self.trees[i])


	def get_leaves(self,forest= True):
		leaves = []
		if (forest):
			for tree in np.arange(self.num_components):
				root =  sorted(self.trees[tree].keys())[0]    if self.trees[tree].keys()[0] >1  else 0 
				curr_cards = self.cardinalities[tree]
				curr_cards_drop_last = curr_cards[:-1]
				num_internal_nodes = np.sum([np.prod(curr_cards_drop_last[:i]) for i in range(1,len(curr_cards_drop_last) + 1 )]) + 1
				total_num_nodes = np.sum([np.prod(curr_cards[:i]) for i in range(1,len(curr_cards) + 1 )])
				leaves = leaves + list( np.arange(root + num_internal_nodes , root + total_num_nodes + 1))
			return(leaves)
		
		else:
			pass
