module DynamicImageElements
	# Interface providing default methods for all elements in composite. Also contain some private methods which helps element to process common tasks.
	module ElementInterface
		# Gives array that contains size of dimensions provided for inner elements.
		# It's calculated as #element_size - <i>padding</i>
		def inner_size
			raise Exception.new("not implemented")
		end
		def draw!(x, y) #:nodoc:
			raise Exception.new("not implemented")
		end
		def surface #:nodoc:
			@parent.surface
		end
		def context #:nodoc:
			@parent.context
		end
		def is_dynamically_sized #:nodoc:
			@parent.is_dynamically_sized
		end

		# Gives array that contains real size of element.
		def element_size
			w, h = inner_size
			if @padding
				w += @padding[1] + @padding[3]
				h += @padding[0] + @padding[2]
			end
			[w, h]
		end

		# Gives array that contains size of space occupied of element.
		# It's calculated as #element_size + <i>margin</i>
		def final_size
			w, h = element_size
			if @margin
				w += @margin[1] + @margin[3]
				h += @margin[0] + @margin[2]
			end
			[w, h]
		end

		private
		def use_options(metakey)
			if metakey == :margin || metakey == :padding
				value = [@options["#{metakey}_top".to_sym].to_i, @options["#{metakey}_right".to_sym].to_i, @options["#{metakey}_bottom".to_sym].to_i, @options["#{metakey}_left".to_sym].to_i]
				if @options[metakey].class == Array
					value = (@options[metakey].map(&:to_i)*4)[0..3]
				else
					value = (@options[metakey].to_s.scan(/\-?\d+/).flatten.map(&:to_i)*4)[0..3] if @options[metakey] && @options[metakey].to_s =~ /\d/
				end
				instance_variable_set "@#{metakey}", value
			end
		end

		OPTIONS_ALIASES = {:w => :width, :h => :height}
		def treat_options(options)
			#convert all to symbols
			options.keys.each do |key|
				next if key.class == Symbol
				options[key.to_s.gsub("-", "_").downcase.to_sym] = options[key]
			end
			#use aliases
			OPTIONS_ALIASES.each do |alias_key, key|
				next unless options[alias_key]
				options[key] = options[alias_key]
			end
		end
	end
end
