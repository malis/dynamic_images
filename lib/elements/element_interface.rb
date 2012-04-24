module DynamicImageElements
	module ElementInterface
		def final_size; raise Exception.new("not implemented");end
		def draw!(x, y); raise Exception.new("not implemented");end
		def surface; @parent.surface;end
		def context; @parent.context;end
		def is_dynamically_sized; @parent.is_dynamically_sized;end

		protected
		def parse(options, metakey)
			if metakey == :margin || metakey == :padding
				value = [options["#{metakey}_top".to_sym].to_i, options["#{metakey}_right".to_sym].to_i, options["#{metakey}_bottom".to_sym].to_i, options["#{metakey}_left".to_sym].to_i]
				if options[metakey].class == Array
					value = (options[metakey].map(&:to_i)*4)[0..3]
				else
					value = (options[metakey].to_s.scan(/\d+/).flatten.map(&:to_i)*4)[0..3] if options[metakey] && options[metakey].to_s =~ /\d/
				end
				instance_variable_set "@#{metakey}", value
			end
		end
	end
end
