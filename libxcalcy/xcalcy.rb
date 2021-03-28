class Xcalcy::Xcalcy
  CYAN = "${color cyan}"
  RED = "${color red}"
  GREEN = "${color green}"
  CLEAR = "${color}"

  def red(str)
    RED + str + CLEAR
  end

  def cyan(str)
    CYAN + str + CLEAR
  end

  def green(str)
    GREEN + str + CLEAR
  end

  ICS_URL = ENV['XCAL_ICS_URL'] || 'https://www.google.com/calendar/ical/ja.japanese%23holiday%40group.v.calendar.google.com/public/basic.ics'

  MONTH_TEMPLATE = [
    "     %年  1月     ",
    "     %年  2月     ",
    "     %年  3月     ",
    "     %年  4月     ",
    "     %年  5月     ",
    "     %年  6月     ",
    "     %年  7月     ",
    "     %年  8月     ",
    "     %年  9月     ",
    "     %年 10月     ",
    "     %年 11月     ",
    "     %年 12月     "
  ]

  MONTH_DAY = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  ROWS = 6
  WEEK = 7
  MONTH = 1
  SPACE = 2

  def header
    [red('日'), '月', '火', '水', '木', '金', cyan('土')]
  end

  def fetch_holidays_from_remote_ics(ics_url)
    holidays = {}
    ical = open(ics_url){|f| f.read}
    cals = Icalendar::Calendar.parse(ical)
    cals.each{|cal|
      cal.events.each{|event|
        start = event.dtstart

        y = start.year
        m = start.month
        d = start.day
        
        holidays[y] = {} unless holidays[y]
        holidays[y][m] = {} unless holidays[y][m]
        holidays[y][m][d] = {holiday: true, date: Date.new(y, m, d), summary: event.summary}
      }
    }

    holidays
  end

  def fill_calendar(year, month, table, month_offset, holidays, today)
    offset = Date.new(year, month, 1).wday - 1
    month_day = get_month_day(year, month)
    (1..month_day).each{|d|
      date = Date.new(year, month, d)

      day = sprintf('%2d', d)
      if today == date
        day = green(day)
      else
        if is_holiday?(year, month, d, holidays)
          day = red(day)
        elsif date.wday == 6
          day = cyan(day)
        elsif date.wday == 0
          day = red(day)
        end
      end

      table[(offset + d) / 7][month_offset + date.wday] = day
    }
  end

  def is_holiday?(y, m, d, holidays)
    holidays[y] and holidays[y][m] and holidays[y][m][d] and holidays[y][m][d][:holiday]
  end

  def month_header(y, m)
    MONTH_TEMPLATE[m - 1].sub('%', sprintf('%4d', y))
  end

  def get_month_day(y, m)
    day = MONTH_DAY[m - 1]
    if m == 2 and Date.leap?(y)
      day += 1
    end
    day
  end

  def main(argv)
    @holidays = fetch_holidays_from_remote_ics(ICS_URL)

    if argv.include?('-3')
      cal3
    else
      cal1
    end
  end

  def cal1
    origin_date = Date.today

    print_1month_calendar(origin_date)
  end

  def cal3
    [-1, 0, 1].each do |offset_month|
      origin_date = Date.today >> (offset_month)

      print_1month_calendar(origin_date)
    end
  end

  def print_1month_calendar(origin_date)
    table = Array.new(ROWS){
      Array.new(WEEK * MONTH){|i|
        (i + 1) % 8 == 0 ? '' : '  ' 
      }
    }

    today = Date.today
    fill_calendar(origin_date.year, origin_date.month, table, 0, @holidays, today)
    month_headers = [
      month_header(origin_date.year, origin_date.month),
    ]
    puts month_headers.join('')

    puts header.join(' ')

    table.each{|row|
      puts row.join(' ')
    }
    first = (Date.today - 31) - (Date.today.day)
    last =  (Date.today + 62) - (Date.today.day)
    list_holidays(first,last)
  end

  def list_holidays(first, last)
    holidays = (first..last).each_with_object([]){|date, memo|
      y = date.year
      m = date.month
      d = date.day

      memo << @holidays[y][m][d] if @holidays[y] && @holidays[y][m] && @holidays[y][m][d]
    }

    holidays.each{|holiday|
      if holiday[:date] == Date.today 
         puts "#{holiday[:date].strftime("%m/")}"+green("#{holiday[:date].strftime("%d")}")+"(#{header[holiday[:date].wday]})#{holiday[:summary]}"
      else
         puts "#{holiday[:date].strftime("%m/")}"+red("#{holiday[:date].strftime("%d")}")+"(#{header[holiday[:date].wday]})#{holiday[:summary]}"
      end
    }
  end
end
