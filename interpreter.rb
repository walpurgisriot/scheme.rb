class Environment
  attr_reader :frame, :outer_env

  def initialize(frame, outer_env=nil)
    @frame = frame
    @outer_env = outer_env
  end

  def self.testing
    env = Environment.new(Hash.new)
  end

  def self.global_env
    Environment.new({:car => lambda{|lat| lat[0]},
                    :cdr => lambda{|lat| lat.drop(1)},
                    :+ => lambda{|x,y| x + y},
                    :- => lambda{|x,y| x - y},
                    :* => lambda{|x,y| x * y},
                    :pi => 3.14159,
                    :"=" => lambda{|x,y| x == y}

                     
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
      # one argument version: lambda{ |arg| Environment.new({ x[1].first => arg }, self).value(x[2]) }
        lambda{ |*args| Environment.new(Hash[x[1].zip(args)], self).value(x[2]) }
      when :if
        value(x[1]) == true ? value(x[2]) : value(x[3])
      
      

      else values = x.map{ |exp| value(exp) }
        values[0].call(*values.drop(1))
    end
  end

end




module Parser

  def self.parse(scheme_string)
    self.read_from(self.tokenize(scheme_string))
  end

  def self.tokenize(scheme_string) # turn scheme input string into array of tokens
    scheme_string.gsub('(', ' ( ').gsub(')', ' ) ').split
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

 env = Environment.global_env
 input = "(+ 2 3)"
 x = Parser.parse(input)
 puts x.inspect
# puts env.value(Parser.parse(input))

