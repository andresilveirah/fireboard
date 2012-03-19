class FireChart
  
  GRAPH_FACTOR = 5.5 # because of chart size limited (yet)
  MAX_CHART_VALUE = 100
  
  attr_accessor :chart_name, :data, :options, :max
  
  # options:
  #   - tooltips: true or false
  #   - axis_scalling: true or false
  #   - path: path wich the chart will be saved
  #   - style: css file's path for the chart 
  def initialize chart_name, data, options = {}
    @current_scale = 1
    @chart_name = chart_name
    @data = data
    @options = options
    @max = 100
  end
  
  # Ex. if a given number n is 10 it'll return 20
  # if that number were 11, or 12, .., 19 this function would return 20
  # In short, what this method do is increase one magnitude order of a given number
  def max_data_value n
    significant = n.to_s[0].to_i + 1
    plus = [1]
    (n.to_s.size - 1).times{
      plus << 0
    }
    if n % plus.join.to_i == 0
      return n
    else
      plus[0] = plus[0] * significant
      return plus.join.to_i
    end
  end
  
  def auto_scale 
    if self.data.max > 100
      @current_scale = (self.data.max / 100.0).ceil
    end
    return @current_scale
  end
  
  def print_scale
    %Q{<rect x="830" y="625" width="150" height="25" fill="white" />
      <text font-family="Verdana" font-size="15" fill="black" x="855" y="643">Escala: #{@current_scale}x</text>
    }
  end

  def generate_shape
    %Q{
      <rect class="outer_shape" x='0' y='0' width='980' height='650' />
      <rect class="inner_shape" x='50' y='50' width='930' height='550' />
    }
  end

  def generate_grid_and_axis args
    if( args[:scale] )
      self.max = max_data_value(@data.max)
      if self.max < MAX_CHART_VALUE
        self.max = MAX_CHART_VALUE
      end
    end
      grid = "<!-- horizontals --> \n"
      11.times{ |n|
        grid <<
        %Q{ <text x="15" y="#{55+n*55}" font-family="Verdana" font-size="15" fill="black" >#{self.max - n*(self.max / 10)}</text>  
        <line class="grid"  x1='50' y1='#{50+n*55}' x2='980' y2='#{50+n*55}'/> 
        }
      }
      grid << "<!-- verticals --> \n"
      31.times{ |n|
        grid << 
        %Q{ <text x="#{45 + 30 * n}" y="620" font-family="Verdana" font-size="15" fill="black" >#{n+1}</text> 
        <line class="grid" x1='#{80 + 30 * n}' y1='600' x2='#{80 + 30 * n}' y2='50'/>
        }
      }

    return grid
  end
  
  def put_chart_title
    %Q{<text x="300" y="25" font-family="Verdana" font-size="20" fill="black" >#{self.chart_name}</text>}
  end
  
  def generate_marks 
    marks = " "
    i = 0
    dia = 50
    while i < self.data.size
      marks += %Q{<circle class ="caption mark" cx='#{dia}' cy='#{600 - self.data[i] * (GRAPH_FACTOR/@current_scale)}' r='4' #{self.tooltip_event(self.data[i])}/> \n}
      i += 1
      dia += 30
    end
    
    if @options[:tooltips]
      marks << %Q{
      <rect class="tooltip_bg" id="tooltip_bg" x="0" y="0" rx="4" ry="4" width="55" height="17" visibility="hidden"/>
      <text class="tooltip" id="tooltip" x="0" y="0" visibility="hidden">Tooltip</text>}
    end
    
    return marks
  end
  
  def generate_data_line
    data_line = "<polyline style='stroke:#2166AC; stroke-width: 2' fill='none'\n       points= ' "

    i = 0
    dia = 50

    while i < self.data.size
      data_line += "                 #{dia}, #{600 - self.data[i] * (GRAPH_FACTOR / @current_scale)} \n"
      i += 1
      dia += 30
    end

    data_line += "'/>"

    return data_line
  end
  
  def generate_tooltips
    %Q{
      <script type="text/ecmascript">
        <![CDATA[
        function init(evt){
          if ( window.svgDocument == null )
          {
            svgDocument = evt.target.ownerDocument;
          }

          tooltip = svgDocument.getElementById('tooltip');
          tooltip_bg = svgDocument.getElementById('tooltip_bg');

        }

        function ShowTooltip(evt, mouseovertext){
          tooltip.setAttributeNS(null,"x",evt.clientX+11);
          tooltip.setAttributeNS(null,"y",evt.clientY+27);
          tooltip.firstChild.data = mouseovertext;
          tooltip.setAttributeNS(null,"visibility","visible");

          length = tooltip.getComputedTextLength();
          tooltip_bg.setAttributeNS(null,"width",length+8);
          tooltip_bg.setAttributeNS(null,"height",30);
          tooltip_bg.setAttributeNS(null,"x",evt.clientX+8);
          tooltip_bg.setAttributeNS(null,"y",evt.clientY+7);
          tooltip_bg.setAttributeNS(null,"visibility","visibile");
        }

        function HideTooltip(evt){
          tooltip.setAttributeNS(null,"visibility","hidden");
          tooltip_bg.setAttributeNS(null,"visibility","hidden");
        }
        ]]>
      </script>
    }
  end
  
  def tooltip_event value
    %Q{onmouseout="HideTooltip(evt)" onmousemove="ShowTooltip(evt, '#{value}')"}
  end
 
  def create_chart options = {}
    auto_scale  # axis without scale are the default
    
    svg_string = %Q{<?xml version='1.0' encoding='UTF-8'?>
      <!DOCTYPE svg PUBLIC '-//W3C//DTD SVG 1.1//EN' 'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd'>
      #{if @options[:style]
        %Q{<?xml-stylesheet href="#{@options[:style]}" type='text/css'?>}
        end
      }
      <svg xmlns='http://www.w3.org/2000/svg' version='1.1' onload="init(evt)">
        
      #{
        if self.options[:tooltips]
          generate_tooltips
        end
      }
      <!-- Axis and Graph Shape -->
      #{generate_shape}
      #{put_chart_title}
      #{
        if self.options[:axis_scalling]
          generate_grid_and_axis(:scale => true)
        else
          generate_grid_and_axis(:scale => false)
          print_scale
        end
      }
      <!-- / Axis and Graph Shape -->
      <!-- Data_Line -->
      #{generate_data_line}
      <!-- / Data_Line -->
      
      <!-- Marks -->
      #{generate_marks}
      <!-- / Marks -->
      
      </svg>
    }
    
    if self.options[:path]
      File.open(self.options[:path],"w"){ |arq| 
        arq.write(svg_string)
      }
    else
      File.open("#{self.chart_name}.svg","w"){ |arq| 
        arq.write(svg_string)
      }
    end
  end
end
