class Environment
  attr_reader :frame, :outer_env

  def initialize(frame, outer_env=nil)
    @frame = frame
    @outer_env = outer_env
  end

  def self.global_env
    Environment.new({:car => lambda{|lat| lat[0]},
                    :cdr => lambda{|lat| lat.drop(1)},
                    :cons => lambda{|a, lat| [a] + lat},
                    :+ => lambda{|x,y| x + y},
                    :- => lambda{|x,y| x - y},
                    :* => lambda{|x,y| x * y},
                    :** => lambda{|x,y| x ** y},
                    :"=" => lambda{|x,y| x == y},
                    :">" => lambda{|x,y| x > y},
                    :"<" => lambda{|x,y| x < y}

                     
                     })
  end

  def env_binding(var) # the environment that binds variable var
    if frame.has_key?(var)
      self
    else outer_env.env_binding(var)
    end
  end

  def value(x)
    return env_binding(x).frame[x] if x.is_a? Symbol # x is a variable
    return x if not x.is_a? Array # x is an atom
    case x[0]
      when :define then frame[x[1]] = value(x[2]); return nil
      when :lambda
        lambda{ |*args| Environment.new(Hash[x[1].zip(args)], self).value(x[2]) }
      when :if
        value(x[1]) == true ? value(x[2]) : value(x[3])
      when :quote then x[1]
      when :begin
        for exp in x.drop(1) do
          value(exp)
        end
          return value(x.last)
      when :set! 
        begin
          env_binding(x[1]).frame[x[1]] = value(x[2])
        rescue 
          puts ". . . oops, #{x[1]} can't be set as it isn't defined"
        end
        #return nil
      else values = x.map{ |exp| value(exp) }
        values[0].call(*values.drop(1))
    end
  end

end


module Parser

  def self.parse(scheme_string)
    self.read_from(self.tokenize(scheme_string))
  end

  def self.tokenize(scheme_string)
    scheme_string.gsub('(', ' ( ').gsub(')', ' ) ').gsub("'", "' ").split
  end

  def self.read_from(tokens)
    raise "empty string!" if tokens.length == 0
    token = tokens.shift
    if token == '('
      l = []
      while tokens.first != ')'
        l.push(read_from(tokens))
      end
      tokens.shift # why do we need this?
      l
    elsif token == ')'
      raise "shouldn't be a right paren"
    else atom(token)
    end    
  end

  def self.atom(token)
    begin 
      Integer(token)
    rescue ArgumentError
      begin 
        Float(token)
      rescue ArgumentError
      token.to_sym
      end
    end
  end

  def self.to_scheme(exp)
    if exp.is_a? Array
      '(' + exp.map{ |x| x.to_s}.join(' ') + ')'
    else exp.to_s
    end
  end

end

class Repl
  attr_reader :input, :env

  def initialize
   @env = Environment.global_env
  end

  def prompt
    print "schemer.b> "
  end

  def read
    @input = gets.chomp
  end

  def evaluate
    @value = env.value(Parser.parse(input))
  end

  def printing
    puts Parser.to_scheme(@value)
  end

end

#  env = Environment.global_env

#  #input = "(if (= 2 1) 0 (if (= 1 1) 1 2)) "
#  #input = "(cons 0 (quote (1 2 3)))"
# #input = "(quote (1 2 3))"
# #input = "(if (= 5 5) (if (= 1 1) 1 2))"
#  x = Parser.parse(input)
#  puts x.inspect

#  val = env.value(Parser.parse(input))
#  puts val.inspect
#  puts Parser.to_scheme(env.value(Parser.parse(input)))

