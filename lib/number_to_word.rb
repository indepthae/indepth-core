require 'i18n'
include I18n

module NumberToWord
  
  def self.t(obj)
    I18n.t(obj)
  end
  
  UNDER_HUNDRED = {""=>"", 0=>t('zero'), 1=>t('one'), 2=>t('two'), 3=>t('three'), 4=>t('four'), 5=>t('five'), 6=>t('six'), 7=>t('seven'), 8=>t('eight'), 9=>t('nine'), 10=>t('ten'), 
    11=>t('eleven'), 12=>t('twelve'), 13=>t('thirteen'), 14=>t('fourteen'), 15=>t('fifteen'), 16=>t('sixteen'), 17=>t('seventeen'), 18=>t('eighteen'), 19=>t('nineteen'), 
    20=>t('twenty'), 21=>t('twenty_one'), 22=>t('twenty_two'), 23=>t('twenty_three'), 24=>t('twenty_four'), 25=>t('twenty_five'), 26=>t('twenty_six'), 27=>t('twenty_seven'), 
    28=>t('twenty_eight'), 29=>t('twenty_nine'), 30=>t('thirty'), 31=>t('thirty_one'), 32=>t('thirty_two'), 33=>t('thirty_three'), 34=>t('thirty_four'), 35=>t('thirty_five'), 
    36=>t('thirty_six'), 37=>t('thirty_seven'), 38=>t('thirty_eight'), 39=>t('thirty_nine'), 40=>t('forty'), 41=>t('forty_one'), 42=>t('forty_two'), 43=>t('forty_three'), 
    44=>t('forty_four'), 45=>t('forty_five'), 46=>t('forty_six'), 47=>t('forty_seven'), 48=>t('forty_eight'), 49=>t('forty_nine'), 50=>t('fifty'), 51=>t('fifty_one'), 
    52=>t('fifty_two'), 53=>t('fifty_three'), 54=>t('fifty_four'), 55=>t('fifty_five'), 56=>t('fifty_six'), 57=>t('fifty_seven'), 58=>t('fifty_eight'), 59=>t('fifty_nine'), 
    60=>t('sixty'), 61=>t('sixty_one'), 62=>t('sixty_two'), 63=>t('sixty_three'), 64=>t('sixty_four'), 65=>t('sixty_five'), 66=>t('sixty_six'), 67=>t('sixty_seven'), 
    68=>t('sixty_eight'), 69=>t('sixty_nine'), 70=>t('seventy'), 71=>t('seventy_one'), 72=>t('seventy_two'), 73=>t('seventy_three'), 74=>t('seventy_four'), 75=>t('seventy_five'), 
    76=>t('seventy_six'), 77=>t('seventy_seven'), 78=>t('seventy_eight'), 79=>t('seventy_nine'), 80=>t('eighty'), 81=>t('eighty_one'), 82=>t('eighty_two'), 83=>t('eighty_three'), 
    84=>t('eighty_four'), 85=>t('eighty_five'), 86=>t('eighty_six'), 87=>t('eighty_seven'), 88=>t('eighty_eight'), 89=>t('eighty_nine'), 90=>t('ninety'), 91=>t('ninety_one'), 
    92=>t('ninety_two'), 93=>t('ninety_three'), 94=>t('ninety_four'), 95=>t('ninety_five'), 96=>t('ninety_six'), 97=>t('ninety_seven'), 98=>t('ninety_eight'), 99=>t('ninety_nine'), 
    100=>t('one_hundred')}
  
  DIVISIONS = ["", t('thousand'), t('million'), t('billion'), t('trillion'), t('quadrillion'), t('quintrillion')]
  
  INDIAN_DIVISIONS = ["", t('thousand'), t('lakh'), t('crore')]

  def self.convert(value,type, currency)
    currency = CURRENCY_DETAILS[currency]
    value_length = value.to_s.split('.')
    value = value_length[0]
    value_p = value_length[1][0..1]
    num = value.to_i
    return ("#{UNDER_HUNDRED[value_p.to_i]} #{currency['subunit']}").capitalize if num < 1
    counter = 0
    result = []
    while num != 0
      if type=="1" and counter > 0
        num, remaining = num.divmod(100)
      else  
        num, remaining = num.divmod(1000)
      end
      p = value_p.to_i > 0 ? 1 : 0
      temp_result = result_below_one_thousand(remaining, counter, p)
      if type=="1"
        result << temp_result + " " + INDIAN_DIVISIONS[counter] + " " if temp_result != ''
      else
        result << temp_result + " " + DIVISIONS[counter] + " " if temp_result != ''
      end
      counter += 1
    end
    amount_in_word = result.reverse.to_s.rstrip
    amount_in_word = amount_in_word.to_s + " #{currency['name']}"
    paisa = UNDER_HUNDRED[value_p.to_i]
    amount_in_word = amount_in_word.to_s + " #{t('currency_and')} #{paisa} #{currency['subunit']}"  if paisa != 'zero'
    return amount_in_word.capitalize
  end

  def self.result_below_one_thousand(num, counter, p=nil)
    hundred, remaining = num.divmod(100)
    return UNDER_HUNDRED[hundred] + " #{t('hundred')} " + UNDER_HUNDRED[remaining]     if hundred != 0 && remaining != 0 && counter != 0
    if p.present? && p == 1
      return UNDER_HUNDRED[hundred] + " #{t('hundred')} " + UNDER_HUNDRED[remaining] if hundred != 0 && remaining != 0
    else
      return UNDER_HUNDRED[hundred] + " #{t('hundred')} #{t('currency_and')} " + UNDER_HUNDRED[remaining] if hundred != 0 && remaining != 0
    end
    return UNDER_HUNDRED[remaining]                                            if hundred == 0 && remaining != 0
    return UNDER_HUNDRED[hundred] + " #{t('hundred')} "                        if hundred != 0 && remaining == 0
    return ''
  end
  
  CURRENCY_DETAILS = {
    "aed"=> {
      "priority"=> 100,
      "iso_code"=> "AED",
      "name"=> t('dirham'),
      "symbol"=> "د.إ",
      "alternate_symbols"=> ["DH", "Dhs"],
      "subunit"=> t('fils'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 25
    },
    "afn"=> {
      "priority"=> 100,
      "iso_code"=> "AFN",
      "name"=> t('afghani'),
      "symbol"=> "؋",
      "alternate_symbols"=> ["Af", "Afs"],
      "subunit"=> t('pul'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "all"=> {
      "priority"=> 100,
      "iso_code"=> "ALL",
      "name"=> t('lek'),
      "symbol"=> "L",
      "disambiguate_symbol"=> t('lek'),
      "alternate_symbols"=> [t('lek')],
      "subunit"=> t('qintar'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "amd"=> {
      "priority"=> 100,
      "iso_code"=> "AMD",
      "name"=> t('dram'),
      "symbol"=> "դր.",
      "alternate_symbols"=> ["dram"],
      "subunit"=> t('luma'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 10
    },
    "ang"=> {
      "priority"=> 100,
      "iso_code"=> "ANG",
      "name"=> t('gulden'),
      "symbol"=> "ƒ",
      "alternate_symbols"=> ["NAƒ", "NAf", "f"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "aoa"=> {
      "priority"=> 100,
      "iso_code"=> "AOA",
      "name"=> t('kwanza'),
      "symbol"=> "Kz",
      "alternate_symbols"=> [],
      "subunit"=> t('centimo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 10
    },
    "ars"=> {
      "priority"=> 100,
      "iso_code"=> "ARS",
      "name"=> t('peso'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "$m/n",
      "alternate_symbols"=> ["$m/n", "m$n"],
      "subunit"=> t('centavo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "aud"=> {
      "priority"=> 4,
      "iso_code"=> "AUD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "A$",
      "alternate_symbols"=> ["A$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "awg"=> {
      "priority"=> 100,
      "iso_code"=> "AWG",
      "name"=> t('florin'),
      "symbol"=> "ƒ",
      "alternate_symbols"=> ["Afl"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "azn"=> {
      "priority"=> 100,
      "iso_code"=> "AZN",
      "name"=> t('manat'),
      "symbol"=> "₼",
      "alternate_symbols"=> ["m", "man"],
      "subunit"=> t('qpik'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "bam"=> {
      "priority"=> 100,
      "iso_code"=> "BAM",
      "name"=> t('mark'),
      "symbol"=> "КМ",
      "alternate_symbols"=> ["KM"],
      "subunit"=> t('fening'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "bbd"=> {
      "priority"=> 100,
      "iso_code"=> "BBD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "Bds$",
      "alternate_symbols"=> ["Bds$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "bdt"=> {
      "priority"=> 100,
      "iso_code"=> "BDT",
      "name"=> t('taka'),
      "symbol"=> "৳",
      "alternate_symbols"=> ["Tk"],
      "subunit"=> t('paisa'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "bgn"=> {
      "priority"=> 100,
      "iso_code"=> "BGN",
      "name"=> t('lev'),
      "symbol"=> "лв.",
      "alternate_symbols"=> ["lev", "leva", "лев", "лева"],
      "subunit"=> t('stotinka'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "bhd"=> {
      "priority"=> 100,
      "iso_code"=> "BHD",
      "name"=> t('dinar'),
      "symbol"=> "ب.د",
      "alternate_symbols"=> ["BD"],
      "subunit"=> t('fils'),
      "subunit_to_unit"=> 1000,
      "smallest_denomination"=> 5
    },
    "bif"=> {
      "priority"=> 100,
      "iso_code"=> "BIF",
      "name"=> t('franc'),
      "symbol"=> "Fr",
      "disambiguate_symbol"=> "FBu",
      "alternate_symbols"=> ["FBu"],
      "subunit"=> t('centime'),
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 100
    },
    "bmd"=> {
      "priority"=> 100,
      "iso_code"=> "BMD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "BD$",
      "alternate_symbols"=> ["BD$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "bnd"=> {
      "priority"=> 100,
      "iso_code"=> "BND",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "BND",
      "alternate_symbols"=> ["B$"],
      "subunit"=> t('sen'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "bob"=> {
      "priority"=> 100,
      "iso_code"=> "BOB",
      "name"=> t('boliviano'),
      "symbol"=> "Bs.",
      "alternate_symbols"=> ["Bs"],
      "subunit"=> t('centavo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 10
    },
    "brl"=> {
      "priority"=> 100,
      "iso_code"=> "BRL",
      "name"=> t('real'),
      "symbol"=> "R$",
      "subunit"=> t('centavo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "bsd"=> {
      "priority"=> 100,
      "iso_code"=> "BSD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "BSD",
      "alternate_symbols"=> ["B$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "btn"=> {
      "priority"=> 100,
      "iso_code"=> "BTN",
      "name"=> t('ngultrum'),
      "symbol"=> "Nu.",
      "alternate_symbols"=> ["Nu"],
      "subunit"=> t('chertrum'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "bwp"=> {
      "priority"=> 100,
      "iso_code"=> "BWP",
      "name"=> t('pula'),
      "symbol"=> "P",
      "alternate_symbols"=> [],
      "subunit"=> t('thebe'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "byn"=> {
      "priority"=> 100,
      "iso_code"=> "BYN",
      "name"=> t('ruble'),
      "symbol"=> "Br",
      "disambiguate_symbol"=> "BYN",
      "alternate_symbols"=> ["бел. руб.", "б.р.", "руб.", "р."],
      "subunit"=> t('kapeyka'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "byr"=> {
      "priority"=> 50,
      "iso_code"=> "BYR",
      "name"=> t('ruble'),
      "symbol"=> "Br",
      "disambiguate_symbol"=> "BYR",
      "alternate_symbols"=> ["бел. руб.", "б.р.", "руб.", "р."],
      "subunit"=> "",
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 100
    },
    "bzd"=> {
      "priority"=> 100,
      "iso_code"=> "BZD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "BZ$",
      "alternate_symbols"=> ["BZ$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "cad"=> {
      "priority"=> 5,
      "iso_code"=> "CAD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "C$",
      "alternate_symbols"=> ["C$", "CAD$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "cdf"=> {
      "priority"=> 100,
      "iso_code"=> "CDF",
      "name"=> t('franc'),
      "symbol"=> "Fr",
      "disambiguate_symbol"=> "FC",
      "alternate_symbols"=> ["FC"],
      "subunit"=> t('centime'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "chf"=> {
      "priority"=> 100,
      "iso_code"=> "CHF",
      "name"=> t('franc'),
      "symbol"=> "CHF",
      "alternate_symbols"=> ["SFr", "Fr"],
      "subunit"=> t('rappen'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "clf"=> {
      "priority"=> 100,
      "iso_code"=> "CLF",
      "name"=> t('unidad_de_fomento'),
      "symbol"=> "UF",
      "alternate_symbols"=> [],
      "subunit"=> t('peso'),
      "subunit_to_unit"=> 10000
    },
    "clp"=> {
      "priority"=> 100,
      "iso_code"=> "CLP",
      "name"=> t('peso'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "CLP",
      "alternate_symbols"=> [],
      "subunit"=> t('peso'),
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 1
    },
    "cny"=> {
      "priority"=> 100,
      "iso_code"=> "CNY",
      "name"=> t('renminbi_yuan'),
      "symbol"=> "¥",
      "alternate_symbols"=> ["CN¥", "元", "CN元"],
      "subunit"=> t('fen'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "cop"=> {
      "priority"=> 100,
      "iso_code"=> "COP",
      "name"=> t('peso'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "COL$",
      "alternate_symbols"=> ["COL$"],
      "subunit"=> t('centavo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 20
    },
    "crc"=> {
      "priority"=> 100,
      "iso_code"=> "CRC",
      "name"=> t('colon'),
      "symbol"=> "₡",
      "alternate_symbols"=> ["¢"],
      "subunit"=> t('centimo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 500
    },
    "cuc"=> {
      "priority"=> 100,
      "iso_code"=> "CUC",
      "name"=> t('convertible_peso'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "CUC$",
      "alternate_symbols"=> ["CUC$"],
      "subunit"=> t('centavo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "cup"=> {
      "priority"=> 100,
      "iso_code"=> "CUP",
      "name"=> t('peso'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "$MN",
      "alternate_symbols"=> ["$MN"],
      "subunit"=> t('centavo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "cve"=> {
      "priority"=> 100,
      "iso_code"=> "CVE",
      "name"=> t('escudo'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "Esc",
      "alternate_symbols"=> ["Esc"],
      "subunit"=> t('centavo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "czk"=> {
      "priority"=> 100,
      "iso_code"=> "CZK",
      "name"=> t('koruna'),
      "symbol"=> "Kč",
      "alternate_symbols"=> [],
      "subunit"=> t('haler'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "djf"=> {
      "priority"=> 100,
      "iso_code"=> "DJF",
      "name"=> t('franc'),
      "symbol"=> "Fdj",
      "alternate_symbols"=> [],
      "subunit"=> t('centime'),
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 100
    },
    "dkk"=> {
      "priority"=> 100,
      "iso_code"=> "DKK",
      "name"=> t('krone'),
      "symbol"=> "kr.",
      "disambiguate_symbol"=> "DKK",
      "alternate_symbols"=> [",-"],
      "subunit"=> t('re'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 50
    },
    "dop"=> {
      "priority"=> 100,
      "iso_code"=> "DOP",
      "name"=> t('peso'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "RD$",
      "alternate_symbols"=> ["RD$"],
      "subunit"=> t('centavo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "dzd"=> {
      "priority"=> 100,
      "iso_code"=> "DZD",
      "name"=> t('dinar'),
      "symbol"=> "د.ج",
      "alternate_symbols"=> ["DA"],
      "subunit"=> t('centime'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "egp"=> {
      "priority"=> 100,
      "iso_code"=> "EGP",
      "name"=> t('pound'),
      "symbol"=> "ج.م",
      "alternate_symbols"=> ["LE", "E£", "L.E."],
      "subunit"=> t('piastre'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 25
    },
    "ern"=> {
      "priority"=> 100,
      "iso_code"=> "ERN",
      "name"=> t('nakfa'),
      "symbol"=> "Nfk",
      "alternate_symbols"=> [],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "etb"=> {
      "priority"=> 100,
      "iso_code"=> "ETB",
      "name"=> t('birr'),
      "symbol"=> "Br",
      "disambiguate_symbol"=> "ETB",
      "alternate_symbols"=> [],
      "subunit"=> t('santim'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "eur"=> {
      "priority"=> 2,
      "iso_code"=> "EUR",
      "name"=> t('euro'),
      "symbol"=> "€",
      "alternate_symbols"=> [],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "fjd"=> {
      "priority"=> 100,
      "iso_code"=> "FJD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "FJ$",
      "alternate_symbols"=> ["FJ$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "fkp"=> {
      "priority"=> 100,
      "iso_code"=> "FKP",
      "name"=> t('pound'),
      "symbol"=> "£",
      "disambiguate_symbol"=> "FK£",
      "alternate_symbols"=> ["FK£"],
      "subunit"=> t('penny'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "gbp"=> {
      "priority"=> 3,
      "iso_code"=> "GBP",
      "name"=> t('pound'),
      "symbol"=> "£",
      "alternate_symbols"=> [],
      "subunit"=> t('penny'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "gel"=> {
      "priority"=> 100,
      "iso_code"=> "GEL",
      "name"=> t('lari'),
      "symbol"=> "ლ",
      "alternate_symbols"=> ["lari"],
      "subunit"=> t('tetri'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "ghs"=> {
      "priority"=> 100,
      "iso_code"=> "GHS",
      "name"=> t('cedi'),
      "symbol"=> "₵",
      "alternate_symbols"=> ["GH¢", "GH₵"],
      "subunit"=> t('pesewa'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "gip"=> {
      "priority"=> 100,
      "iso_code"=> "GIP",
      "name"=> t('pound'),
      "symbol"=> "£",
      "disambiguate_symbol"=> "GIP",
      "alternate_symbols"=> [],
      "subunit"=> t('penny'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "gmd"=> {
      "priority"=> 100,
      "iso_code"=> "GMD",
      "name"=> t('dalasi'),
      "symbol"=> "D",
      "alternate_symbols"=> [],
      "subunit"=> t('butut'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "gnf"=> {
      "priority"=> 100,
      "iso_code"=> "GNF",
      "name"=> t('franc'),
      "symbol"=> "Fr",
      "disambiguate_symbol"=> "FG",
      "alternate_symbols"=> ["FG", "GFr"],
      "subunit"=> t('centime'),
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 100
    },
    "gtq"=> {
      "priority"=> 100,
      "iso_code"=> "GTQ",
      "name"=> t('quetzal'),
      "symbol"=> "Q",
      "alternate_symbols"=> [],
      "subunit"=> t('centavo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "gyd"=> {
      "priority"=> 100,
      "iso_code"=> "GYD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "G$",
      "alternate_symbols"=> ["G$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "hkd"=> {
      "priority"=> 100,
      "iso_code"=> "HKD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "HK$",
      "alternate_symbols"=> ["HK$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 10
    },
    "hnl"=> {
      "priority"=> 100,
      "iso_code"=> "HNL",
      "name"=> t('lempira'),
      "symbol"=> "L",
      "disambiguate_symbol"=> "HNL",
      "alternate_symbols"=> [],
      "subunit"=> t('centavo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "hrk"=> {
      "priority"=> 100,
      "iso_code"=> "HRK",
      "name"=> t('kuna'),
      "symbol"=> "kn",
      "alternate_symbols"=> [],
      "subunit"=> t('lipa'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "htg"=> {
      "priority"=> 100,
      "iso_code"=> "HTG",
      "name"=> t('gourde'),
      "symbol"=> "G",
      "alternate_symbols"=> [],
      "subunit"=> t('centime'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "huf"=> {
      "priority"=> 100,
      "iso_code"=> "HUF",
      "name"=> t('forint'),
      "symbol"=> "Ft",
      "alternate_symbols"=> [],
      "subunit"=> "",
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 5
    },
    "idr"=> {
      "priority"=> 100,
      "iso_code"=> "IDR",
      "name"=> t('rupiah'),
      "symbol"=> "Rp",
      "alternate_symbols"=> [],
      "subunit"=> t('sen'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5000
    },
    "ils"=> {
      "priority"=> 100,
      "iso_code"=> "ILS",
      "name"=> t('new_sheqel'),
      "symbol"=> "₪",
      "alternate_symbols"=> ["ש״ח", "NIS"],
      "subunit"=> t('agora'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 10
    },
    "inr"=> {
      "priority"=> 100,
      "iso_code"=> "INR",
      "name"=> t('rupee'),
      "symbol"=> "₹",
      "alternate_symbols"=> ["Rs", "৳", "૱", "௹", "रु", "₨"],
      "subunit"=> t('paisa'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 50
    },
    "iqd"=> {
      "priority"=> 100,
      "iso_code"=> "IQD",
      "name"=> t('dinar'),
      "symbol"=> "ع.د",
      "alternate_symbols"=> [],
      "subunit"=> t('fils'),
      "subunit_to_unit"=> 1000,
      "smallest_denomination"=> 50000
    },
    "irr"=> {
      "priority"=> 100,
      "iso_code"=> "IRR",
      "name"=> t('rial'),
      "symbol"=> "﷼",
      "alternate_symbols"=> [],
      "subunit"=> "",
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5000
    },
    "isk"=> {
      "priority"=> 100,
      "iso_code"=> "ISK",
      "name"=> t('krona'),
      "symbol"=> "kr",
      "alternate_symbols"=> ["Íkr"],
      "subunit"=> "",
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 1
    },
    "jmd"=> {
      "priority"=> 100,
      "iso_code"=> "JMD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "J$",
      "alternate_symbols"=> ["J$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "jod"=> {
      "priority"=> 100,
      "iso_code"=> "JOD",
      "name"=> t('dinar'),
      "symbol"=> "د.ا",
      "alternate_symbols"=> ["JD"],
      "subunit"=> t('fils'),
      "subunit_to_unit"=> 1000,
      "smallest_denomination"=> 5
    },
    "jpy"=> {
      "priority"=> 6,
      "iso_code"=> "JPY",
      "name"=> t('yen'),
      "symbol"=> "¥",
      "alternate_symbols"=> ["円", "圓"],
      "subunit"=> "",
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 1
    },
    "kes"=> {
      "priority"=> 100,
      "iso_code"=> "KES",
      "name"=> t('shilling'),
      "symbol"=> "KSh",
      "alternate_symbols"=> ["Sh"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 50
    },
    "kgs"=> {
      "priority"=> 100,
      "iso_code"=> "KGS",
      "name"=> t('som'),
      "symbol"=> "som",
      "alternate_symbols"=> ["сом"],
      "subunit"=> t('tyiyn'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "khr"=> {
      "priority"=> 100,
      "iso_code"=> "KHR",
      "name"=> t('riel'),
      "symbol"=> "៛",
      "alternate_symbols"=> [],
      "subunit"=> t('sen'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5000
    },
    "kmf"=> {
      "priority"=> 100,
      "iso_code"=> "KMF",
      "name"=> t('franc'),
      "symbol"=> "Fr",
      "disambiguate_symbol"=> "CF",
      "alternate_symbols"=> ["CF"],
      "subunit"=> t('centime'),
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 100
    },
    "kpw"=> {
      "priority"=> 100,
      "iso_code"=> "KPW",
      "name"=> t('won'),
      "symbol"=> "₩",
      "alternate_symbols"=> [],
      "subunit"=> t('chon'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "krw"=> {
      "priority"=> 100,
      "iso_code"=> "KRW",
      "name"=> t('won'),
      "symbol"=> "₩",
      "subunit"=> "",
      "subunit_to_unit"=> 1,
      "alternate_symbols"=> [],
      "smallest_denomination"=> 1
    },
    "kwd"=> {
      "priority"=> 100,
      "iso_code"=> "KWD",
      "name"=> t('dinar'),
      "symbol"=> "د.ك",
      "alternate_symbols"=> ["K.D."],
      "subunit"=> t('fils'),
      "subunit_to_unit"=> 1000,
      "smallest_denomination"=> 5
    },
    "kyd"=> {
      "priority"=> 100,
      "iso_code"=> "KYD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "CI$",
      "alternate_symbols"=> ["CI$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "kzt"=> {
      "priority"=> 100,
      "iso_code"=> "KZT",
      "name"=> t('tenge'),
      "symbol"=> "₸",
      "alternate_symbols"=> [],
      "subunit"=> t('tiyn'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "lak"=> {
      "priority"=> 100,
      "iso_code"=> "LAK",
      "name"=> t('kip'),
      "symbol"=> "₭",
      "alternate_symbols"=> ["₭N"],
      "subunit"=> t('att'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 10
    },
    "lbp"=> {
      "priority"=> 100,
      "iso_code"=> "LBP",
      "name"=> t('pound'),
      "symbol"=> "ل.ل",
      "alternate_symbols"=> ["£", "L£"],
      "subunit"=> t('piastre'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 25000
    },
    "lkr"=> {
      "priority"=> 100,
      "iso_code"=> "LKR",
      "name"=> t('rupee'),
      "symbol"=> "₨",
      "disambiguate_symbol"=> "SLRs",
      "alternate_symbols"=> ["රු", "ரூ", "SLRs", "/-"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "lrd"=> {
      "priority"=> 100,
      "iso_code"=> "LRD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "L$",
      "alternate_symbols"=> ["L$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "lsl"=> {
      "priority"=> 100,
      "iso_code"=> "LSL",
      "name"=> t('loti'),
      "symbol"=> "L",
      "disambiguate_symbol"=> "M",
      "alternate_symbols"=> ["M"],
      "subunit"=> t('sente'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "ltl"=> {
      "priority"=> 100,
      "iso_code"=> "LTL",
      "name"=> t('litas'),
      "symbol"=> "Lt",
      "alternate_symbols"=> [],
      "subunit"=> t('centas'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "lvl"=> {
      "priority"=> 100,
      "iso_code"=> "LVL",
      "name"=> t('lats'),
      "symbol"=> "Ls",
      "alternate_symbols"=> [],
      "subunit"=> t('santims'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "lyd"=> {
      "priority"=> 100,
      "iso_code"=> "LYD",
      "name"=> t('dinar'),
      "symbol"=> "ل.د",
      "alternate_symbols"=> ["LD"],
      "subunit"=> t('dirham'),
      "subunit_to_unit"=> 1000,
      "smallest_denomination"=> 50
    },
    "mad"=> {
      "priority"=> 100,
      "iso_code"=> "MAD",
      "name"=> t('dirham'),
      "symbol"=> "د.م.",
      "alternate_symbols"=> [],
      "subunit"=> t('centime'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "mdl"=> {
      "priority"=> 100,
      "iso_code"=> "MDL",
      "name"=> t('leu'),
      "symbol"=> "L",
      "alternate_symbols"=> ["lei"],
      "subunit"=> t('ban'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "mga"=> {
      "priority"=> 100,
      "iso_code"=> "MGA",
      "name"=> t('ariary'),
      "symbol"=> "Ar",
      "alternate_symbols"=> [],
      "subunit"=> t('iraimbilanja'),
      "subunit_to_unit"=> 5,
      "smallest_denomination"=> 1
    },
    "mkd"=> {
      "priority"=> 100,
      "iso_code"=> "MKD",
      "name"=> t('denar'),
      "symbol"=> "ден",
      "alternate_symbols"=> [],
      "subunit"=> t('deni'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "mmk"=> {
      "priority"=> 100,
      "iso_code"=> "MMK",
      "name"=> t('kyat'),
      "symbol"=> "K",
      "disambiguate_symbol"=> "MMK",
      "alternate_symbols"=> [],
      "subunit"=> t('pya'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 50
    },
    "mnt"=> {
      "priority"=> 100,
      "iso_code"=> "MNT",
      "name"=> t('togrog'),
      "symbol"=> "₮",
      "alternate_symbols"=> [],
      "subunit"=> t('mongo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 2000
    },
    "mop"=> {
      "priority"=> 100,
      "iso_code"=> "MOP",
      "name"=> t('pataca'),
      "symbol"=> "P",
      "alternate_symbols"=> ["MOP$"],
      "subunit"=> t('avo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 10
    },
    "mro"=> {
      "priority"=> 100,
      "iso_code"=> "MRO",
      "name"=> t('ouguiya'),
      "symbol"=> "UM",
      "alternate_symbols"=> [],
      "subunit"=> t('khoums'),
      "subunit_to_unit"=> 5,
      "smallest_denomination"=> 1
    },
    "mur"=> {
      "priority"=> 100,
      "iso_code"=> "MUR",
      "name"=> t('rupee'),
      "symbol"=> "₨",
      "alternate_symbols"=> [],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "mvr"=> {
      "priority"=> 100,
      "iso_code"=> "MVR",
      "name"=> t('rufiyaa'),
      "symbol"=> "MVR",
      "alternate_symbols"=> ["MRF", "Rf", "/-", "ރ"],
      "subunit"=> t('laari'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "mwk"=> {
      "priority"=> 100,
      "iso_code"=> "MWK",
      "name"=> t('kwacha'),
      "symbol"=> "MK",
      "alternate_symbols"=> [],
      "subunit"=> t('tambala'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "mxn"=> {
      "priority"=> 100,
      "iso_code"=> "MXN",
      "name"=> t('peso'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "MEX$",
      "alternate_symbols"=> ["MEX$"],
      "subunit"=> t('centavo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "myr"=> {
      "priority"=> 100,
      "iso_code"=> "MYR",
      "name"=> t('ringgit'),
      "symbol"=> "RM",
      "alternate_symbols"=> [],
      "subunit"=> t('sen'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "mzn"=> {
      "priority"=> 100,
      "iso_code"=> "MZN",
      "name"=> t('metical'),
      "symbol"=> "MTn",
      "alternate_symbols"=> ["MZN"],
      "subunit"=> t('centavo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "nad"=> {
      "priority"=> 100,
      "iso_code"=> "NAD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "N$",
      "alternate_symbols"=> ["N$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "ngn"=> {
      "priority"=> 100,
      "iso_code"=> "NGN",
      "name"=> t('naira'),
      "symbol"=> "₦",
      "alternate_symbols"=> [],
      "subunit"=> t('kobo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 50
    },
    "nio"=> {
      "priority"=> 100,
      "iso_code"=> "NIO",
      "name"=> t('cordoba'),
      "symbol"=> "C$",
      "disambiguate_symbol"=> "NIO$",
      "alternate_symbols"=> [],
      "subunit"=> t('centavo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "nok"=> {
      "priority"=> 100,
      "iso_code"=> "NOK",
      "name"=> t('krone'),
      "symbol"=> "kr",
      "disambiguate_symbol"=> "NOK",
      "alternate_symbols"=> [",-"],
      "subunit"=> t('re'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "npr"=> {
      "priority"=> 100,
      "iso_code"=> "NPR",
      "name"=> t('rupee'),
      "symbol"=> "₨",
      "disambiguate_symbol"=> "NPR",
      "alternate_symbols"=> ["Rs", "रू"],
      "subunit"=> t('paisa'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "nzd"=> {
      "priority"=> 100,
      "iso_code"=> "NZD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "NZ$",
      "alternate_symbols"=> ["NZ$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 10
    },
    "omr"=> {
      "priority"=> 100,
      "iso_code"=> "OMR",
      "name"=> t('rial'),
      "symbol"=> "ر.ع.",
      "alternate_symbols"=> [],
      "subunit"=> t('baisa'),
      "subunit_to_unit"=> 1000,
      "smallest_denomination"=> 5
    },
    "pab"=> {
      "priority"=> 100,
      "iso_code"=> "PAB",
      "name"=> t('balboa'),
      "symbol"=> "B/.",
      "alternate_symbols"=> [],
      "subunit"=> t('centesimo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "pen"=> {
      "priority"=> 100,
      "iso_code"=> "PEN",
      "name"=> t('sol'),
      "symbol"=> "S/.",
      "alternate_symbols"=> [],
      "subunit"=> t('centimo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "pgk"=> {
      "priority"=> 100,
      "iso_code"=> "PGK",
      "name"=> t('kina'),
      "symbol"=> "K",
      "disambiguate_symbol"=> "PGK",
      "alternate_symbols"=> [],
      "subunit"=> t('toea'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "php"=> {
      "priority"=> 100,
      "iso_code"=> "PHP",
      "name"=> t('peso'),
      "symbol"=> "₱",
      "alternate_symbols"=> ["PHP", "PhP", "P"],
      "subunit"=> t('centavo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "pkr"=> {
      "priority"=> 100,
      "iso_code"=> "PKR",
      "name"=> t('rupee'),
      "symbol"=> "₨",
      "disambiguate_symbol"=> "PKR",
      "alternate_symbols"=> ["Rs"],
      "subunit"=> t('paisa'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "pln"=> {
      "priority"=> 100,
      "iso_code"=> "PLN",
      "name"=> t('zoty'),
      "symbol"=> "zł",
      "alternate_symbols"=> [],
      "subunit"=> t('grosz'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "pyg"=> {
      "priority"=> 100,
      "iso_code"=> "PYG",
      "name"=> t('guarani'),
      "symbol"=> "₲",
      "alternate_symbols"=> [],
      "subunit"=> t('centimo'),
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 5000
    },
    "qar"=> {
      "priority"=> 100,
      "iso_code"=> "QAR",
      "name"=> t('riyal'),
      "symbol"=> "ر.ق",
      "alternate_symbols"=> ["QR"],
      "subunit"=> t('dirham'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "ron"=> {
      "priority"=> 100,
      "iso_code"=> "RON",
      "name"=> t('leu'),
      "symbol"=> "Lei",
      "alternate_symbols"=> [],
      "subunit"=> t('bani'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "rsd"=> {
      "priority"=> 100,
      "iso_code"=> "RSD",
      "name"=> t('dinar'),
      "symbol"=> "РСД",
      "alternate_symbols"=> ["RSD", "din", "дин"],
      "subunit"=> t('para'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "rub"=> {
      "priority"=> 100,
      "iso_code"=> "RUB",
      "name"=> t('ruble'),
      "symbol"=> "₽",
      "alternate_symbols"=> ["руб.", "р."],
      "subunit"=> t('kopeck'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "rwf"=> {
      "priority"=> 100,
      "iso_code"=> "RWF",
      "name"=> t('franc'),
      "symbol"=> "FRw",
      "alternate_symbols"=> ["RF", "R₣"],
      "subunit"=> t('centime'),
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 100
    },
    "sar"=> {
      "priority"=> 100,
      "iso_code"=> "SAR",
      "name"=> t('riyal'),
      "symbol"=> "ر.س",
      "alternate_symbols"=> ["SR", "﷼"],
      "subunit"=> t('hallallah'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "sbd"=> {
      "priority"=> 100,
      "iso_code"=> "SBD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "SI$",
      "alternate_symbols"=> ["SI$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 10
    },
    "scr"=> {
      "priority"=> 100,
      "iso_code"=> "SCR",
      "name"=> t('rupee'),
      "symbol"=> "₨",
      "disambiguate_symbol"=> "SRe",
      "alternate_symbols"=> ["SRe", "SR"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "sdg"=> {
      "priority"=> 100,
      "iso_code"=> "SDG",
      "name"=> t('pound'),
      "symbol"=> "£",
      "disambiguate_symbol"=> "SDG",
      "alternate_symbols"=> [],
      "subunit"=> t('piastre'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "sek"=> {
      "priority"=> 100,
      "iso_code"=> "SEK",
      "name"=> t('krona'),
      "symbol"=> "kr",
      "disambiguate_symbol"=> "SEK",
      "alternate_symbols"=> ["=>-"],
      "subunit"=> t('ore'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "sgd"=> {
      "priority"=> 100,
      "iso_code"=> "SGD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "S$",
      "alternate_symbols"=> ["S$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "shp"=> {
      "priority"=> 100,
      "iso_code"=> "SHP",
      "name"=> t('pound'),
      "symbol"=> "£",
      "disambiguate_symbol"=> "SHP",
      "alternate_symbols"=> [],
      "subunit"=> t('penny'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "skk"=> {
      "priority"=> 100,
      "iso_code"=> "SKK",
      "name"=> t('koruna'),
      "symbol"=> "Sk",
      "alternate_symbols"=> [],
      "subunit"=> t('halier'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 50
    },
    "sll"=> {
      "priority"=> 100,
      "iso_code"=> "SLL",
      "name"=> t('leone'),
      "symbol"=> "Le",
      "alternate_symbols"=> [],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1000
    },
    "sos"=> {
      "priority"=> 100,
      "iso_code"=> "SOS",
      "name"=> t('shilling'),
      "symbol"=> "Sh",
      "alternate_symbols"=> ["Sh.So"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "srd"=> {
      "priority"=> 100,
      "iso_code"=> "SRD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "SRD",
      "alternate_symbols"=> [],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "ssp"=> {
      "priority"=> 100,
      "iso_code"=> "SSP",
      "name"=> t('pound'),
      "symbol"=> "£",
      "disambiguate_symbol"=> "SSP",
      "alternate_symbols"=> [],
      "subunit"=> t('piaster'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "std"=> {
      "priority"=> 100,
      "iso_code"=> "STD",
      "name"=> t('dobra'),
      "symbol"=> "Db",
      "alternate_symbols"=> [],
      "subunit"=> t('centimo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 10000
    },
    "svc"=> {
      "priority"=> 100,
      "iso_code"=> "SVC",
      "name"=> t('colon'),
      "symbol"=> "₡",
      "alternate_symbols"=> ["¢"],
      "subunit"=> t('centavo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "syp"=> {
      "priority"=> 100,
      "iso_code"=> "SYP",
      "name"=> t('pound'),
      "symbol"=> "£S",
      "alternate_symbols"=> ["£", "ل.س", "LS", "الليرة السورية"],
      "subunit"=> t('piastre'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "szl"=> {
      "priority"=> 100,
      "iso_code"=> "SZL",
      "name"=> t('lilangeni'),
      "symbol"=> "E",
      "disambiguate_symbol"=> "SZL",
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "thb"=> {
      "priority"=> 100,
      "iso_code"=> "THB",
      "name"=> t('baht'),
      "symbol"=> "฿",
      "alternate_symbols"=> [],
      "subunit"=> t('satang'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "tjs"=> {
      "priority"=> 100,
      "iso_code"=> "TJS",
      "name"=> t('somoni'),
      "symbol"=> "ЅМ",
      "alternate_symbols"=> [],
      "subunit"=> t('diram'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "tmt"=> {
      "priority"=> 100,
      "iso_code"=> "TMT",
      "name"=> t('manat'),
      "symbol"=> "T",
      "alternate_symbols"=> [],
      "subunit"=> t('tenge'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "tnd"=> {
      "priority"=> 100,
      "iso_code"=> "TND",
      "name"=> t('dinar'),
      "symbol"=> "د.ت",
      "alternate_symbols"=> ["TD", "DT"],
      "subunit"=> t('millime'),
      "subunit_to_unit"=> 1000,
      "smallest_denomination"=> 10
    },
    "top"=> {
      "priority"=> 100,
      "iso_code"=> "TOP",
      "name"=> t('paanga'),
      "symbol"=> "T$",
      "alternate_symbols"=> ["PT"],
      "subunit"=> t('seniti'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "try"=> {
      "priority"=> 100,
      "iso_code"=> "TRY",
      "name"=> t('lira'),
      "symbol"=> "₺",
      "alternate_symbols"=> ["TL"],
      "subunit"=> t('kurus'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "ttd"=> {
      "priority"=> 100,
      "iso_code"=> "TTD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "TT$",
      "alternate_symbols"=> ["TT$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "twd"=> {
      "priority"=> 100,
      "iso_code"=> "TWD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "NT$",
      "alternate_symbols"=> ["NT$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 50
    },
    "tzs"=> {
      "priority"=> 100,
      "iso_code"=> "TZS",
      "name"=> t('shilling'),
      "symbol"=> "Sh",
      "alternate_symbols"=> [],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5000
    },
    "uah"=> {
      "priority"=> 100,
      "iso_code"=> "UAH",
      "name"=> t('hryvnia'),
      "symbol"=> "₴",
      "alternate_symbols"=> [],
      "subunit"=> t('kopiyka'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "ugx"=> {
      "priority"=> 100,
      "iso_code"=> "UGX",
      "name"=> t('shilling'),
      "symbol"=> "USh",
      "alternate_symbols"=> [],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 1000
    },
    "usd"=> {
      "priority"=> 1,
      "iso_code"=> "USD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "US$",
      "alternate_symbols"=> ["US$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "uyu"=> {
      "priority"=> 100,
      "iso_code"=> "UYU",
      "name"=> t('peso'),
      "symbol"=> "$",
      "alternate_symbols"=> ["$U"],
      "subunit"=> t('centesimo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "uzs"=> {
      "priority"=> 100,
      "iso_code"=> "UZS",
      "name"=> t('som'),
      "symbol"=> "",
      "alternate_symbols"=> ["so‘m", "сўм", "сум", "s", "с"],
      "subunit"=> t('tiyin'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "vef"=> {
      "priority"=> 100,
      "iso_code"=> "VEF",
      "name"=> t('bolivar'),
      "symbol"=> "Bs",
      "alternate_symbols"=> ["Bs.F"],
      "subunit"=> t('centimo'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "vnd"=> {
      "priority"=> 100,
      "iso_code"=> "VND",
      "name"=> t('ong'),
      "symbol"=> "₫",
      "alternate_symbols"=> [],
      "subunit"=> t('hao'),
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 100
    },
    "vuv"=> {
      "priority"=> 100,
      "iso_code"=> "VUV",
      "name"=> t('vatu'),
      "symbol"=> "Vt",
      "alternate_symbols"=> [],
      "subunit"=> "",
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 1
    },
    "wst"=> {
      "priority"=> 100,
      "iso_code"=> "WST",
      "name"=> t('tala'),
      "symbol"=> "T",
      "disambiguate_symbol"=> "WS$",
      "alternate_symbols"=> ["WS$", "SAT", "ST"],
      "subunit"=> t('sene'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 10
    },
    "xaf"=> {
      "priority"=> 100,
      "iso_code"=> "XAF",
      "name"=> t('cfa_franc'),
      "symbol"=> "Fr",
      "disambiguate_symbol"=> "FCFA",
      "alternate_symbols"=> ["FCFA"],
      "subunit"=> t('centime'),
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 100
    },
    "xag"=> {
      "priority"=> 100,
      "iso_code"=> "XAG",
      "name"=> t('silver_troy_ounce'),
      "symbol"=> "oz t",
      "disambiguate_symbol"=> "XAG",
      "alternate_symbols"=> [],
      "subunit"=> t('oz'),
      "subunit_to_unit"=> 1
    },
    "xau"=> {
      "priority"=> 100,
      "iso_code"=> "XAU",
      "name"=> t('gold_troy_ounce'),
      "symbol"=> "oz t",
      "disambiguate_symbol"=> "XAU",
      "alternate_symbols"=> [],
      "subunit"=> t('oz'),
      "subunit_to_unit"=> 1
    },
    "xba"=> {
      "priority"=> 100,
      "iso_code"=> "XBA",
      "name"=> t('european_composite_unit'),
      "symbol"=> "",
      "disambiguate_symbol"=> "XBA",
      "alternate_symbols"=> [],
      "subunit"=> "",
      "subunit_to_unit"=> 1
    },
    "xbb"=> {
      "priority"=> 100,
      "iso_code"=> "XBB",
      "name"=> t('european_monetary_unit'),
      "symbol"=> "",
      "disambiguate_symbol"=> "XBB",
      "alternate_symbols"=> [],
      "subunit"=> "",
      "subunit_to_unit"=> 1
    },
    "xbc"=> {
      "priority"=> 100,
      "iso_code"=> "XBC",
      "name"=> t('european_unit_of_account_9'),
      "symbol"=> "",
      "disambiguate_symbol"=> "XBC",
      "alternate_symbols"=> [],
      "subunit"=> "",
      "subunit_to_unit"=> 1
    },
    "xbd"=> {
      "priority"=> 100,
      "iso_code"=> "XBD",
      "name"=> t('european_unit_of_account_17'),
      "symbol"=> "",
      "disambiguate_symbol"=> "XBD",
      "alternate_symbols"=> [],
      "subunit"=> "",
      "subunit_to_unit"=> 1
    },
    "xcd"=> {
      "priority"=> 100,
      "iso_code"=> "XCD",
      "name"=> t('dollar'),
      "symbol"=> "$",
      "disambiguate_symbol"=> "EX$",
      "alternate_symbols"=> ["EC$"],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 1
    },
    "xdr"=> {
      "priority"=> 100,
      "iso_code"=> "XDR",
      "name"=> t('special_drawing_rights'),
      "symbol"=> "SDR",
      "alternate_symbols"=> ["XDR"],
      "subunit"=> "",
      "subunit_to_unit"=> 1,
      "iso_numeric"=> "960"
    },
    "xof"=> {
      "priority"=> 100,
      "iso_code"=> "XOF",
      "name"=> t('franc'),
      "symbol"=> "Fr",
      "disambiguate_symbol"=> "CFA",
      "alternate_symbols"=> ["CFA"],
      "subunit"=> t('centime'),
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 100
    },
    "xpd"=> {
      "priority"=> 100,
      "iso_code"=> "XPD",
      "name"=> t('palladium'),
      "symbol"=> "oz t",
      "disambiguate_symbol"=> "XPD",
      "alternate_symbols"=> [],
      "subunit"=> t('oz'),
      "subunit_to_unit"=> 1
    },
    "xpf"=> {
      "priority"=> 100,
      "iso_code"=> "XPF",
      "name"=> t('cfp_franc'),
      "symbol"=> "Fr",
      "alternate_symbols"=> ["F"],
      "subunit"=> t('centime'),
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> 100
    },
    "xpt"=> {
      "priority"=> 100,
      "iso_code"=> "XPT",
      "name"=> t('platinum'),
      "symbol"=> "oz t",
      "alternate_symbols"=> [],
      "subunit"=> "",
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> ""
    },
    "xts"=> {
      "priority"=> 100,
      "iso_code"=> "XTS",
      "name"=> t('codes_specifically_reserved_for_testing_purposes'),
      "symbol"=> "",
      "alternate_symbols"=> [],
      "subunit"=> "",
      "subunit_to_unit"=> 1,
      "smallest_denomination"=> ""
    },
    "yer"=> {
      "priority"=> 100,
      "iso_code"=> "YER",
      "name"=> t('rial'),
      "symbol"=> "﷼",
      "alternate_symbols"=> [],
      "subunit"=> t('fils'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 100
    },
    "zar"=> {
      "priority"=> 100,
      "iso_code"=> "ZAR",
      "name"=> t('rand'),
      "symbol"=> "R",
      "alternate_symbols"=> [],
      "subunit"=> t('cent'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 10
    },
    "zmk"=> {
      "priority"=> 100,
      "iso_code"=> "ZMK",
      "name"=> t('kwacha'),
      "symbol"=> "ZK",
      "disambiguate_symbol"=> "ZMK",
      "alternate_symbols"=> [],
      "subunit"=> t('ngwee'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    },
    "zmw"=> {
      "priority"=> 100,
      "iso_code"=> "ZMW",
      "name"=> t('kwacha'),
      "symbol"=> "ZK",
      "disambiguate_symbol"=> "ZMW",
      "alternate_symbols"=> [],
      "subunit"=> t('ngwee'),
      "subunit_to_unit"=> 100,
      "smallest_denomination"=> 5
    }
  }
end