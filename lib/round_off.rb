# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module RoundOff
  ROUND_OFF = {
    1 => "no_rounding",
    2=> "nearest_1",
    3=> "nearest_5",
    4=>"nearest_10",
    5=>"round_off"  
  }
  def rounding_up(net_pay, rounding_up_for)
    to_round_down = [1,2,6,7]
    mod_op = {2=> 1, 3=>5, 4=>10}
    if rounding_up_for.present?
      case (ROUND_OFF[rounding_up_for])
      when "nearest_1"
        value = net_pay - net_pay.to_i
        if value >= 0.5
          net_pay = net_pay.to_i + 1
        else value < 0.5
          net_pay = net_pay.to_i
        end
      when "nearest_5"
        if to_round_down.include?(net_pay.to_i % 5)
          net_pay = ((net_pay.to_i) - (net_pay.to_i % 5))
        elsif (net_pay.to_i % 5) == 0
          net_pay = net_pay.to_i
        else
          net_pay = ((net_pay.to_i) + ( 5 - (net_pay.to_i % 5 )))
        end
      when "nearest_10"
        if (net_pay.to_i % 10) >= 5
          net_pay = ((net_pay.to_i) + ( 10 - (net_pay.to_i % 10 )))
        else
          net_pay = ((net_pay.to_i) - (net_pay.to_i % 10))
        end
      when "round_off"
        net_pay = net_pay.ceil
      end
    else
      net_pay = net_pay
    end
    return net_pay
  end
end
