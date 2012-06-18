require 'ruby-growl';
require 'net/http';
require 'nokogiri';
require 'yaml'


class FDChecker
  attr_accessor :url, :u_login, :u_pass, :u_id, :growl, :cnt_undef, :cnt_yours 
  
  def initialize(url, login, pass, uid)
    @url = url
    @u_login = login
    @u_pass = pass
    @u_id = uid
    @cnt_undef = 0
    @cnt_yours = 0
    @growl = Growl.new "localhost", "ruby-growl"
    @growl.add_notification "check"
  end
  
  def run
    while true
      self.check
      sleep 60 * 5
    end
  end
  
  def check
    cnt_undef = 0
    cnt_yours = 0
    Net::HTTP.start(@url) {|http|
      req = Net::HTTP::Get.new('/helpdesk/tickets.xml')
      req.basic_auth @u_login, @u_pass
      response = http.request(req)
      doc = Nokogiri::XML(response.body)
      doc.xpath('//subject/..').each do |ticket|
        puts ticket.at_xpath('@nil')
        if ticket.at_xpath('//*[18]').inner_html == @u_id
          cnt_yours += 1
        end
        if true
          cnt_undef += 1
        end
      end
      #puts doc.inspect
    }
    if cnt_undef > @cnt_undef
      @growl.notify "check", "FreshDesk.Ticket", "Wszystkie tickety: "+cnt_undef.to_s()
    end
    if cnt_yours > @cnt_yours
      @growl.notify "check", "FreshDesk.Ticket", "Masz nowy ticket. Lacznie: "+cnt_yours.to_s()
    end
    @cnt_undef = cnt_undef
    @cnt_yours = cnt_yours
  end
end


user = YAML.load_file('user.yaml')
checker = FDChecker.new(user['url'], user['login'], user['pass'], user['uid'])
checker.run