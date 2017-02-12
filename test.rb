#!/usr/bin/env ruby

require 'minitest/autorun'
require 'net/http'
require 'pp'
require 'json'

class TestMeme < Minitest::Test
  def setup
    @redir_resp_exp = [301, "https://www.koszek.us/"]
  end

  def http_code_for_url(url_str)
    url = URI.parse(url_str)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    return [ res.code.to_i, res['location']]
  end

  def test_koszek_redirect_http
    assert_equal @redir_resp_exp, http_code_for_url("http://koszek.co")
    assert_equal @redir_resp_exp, http_code_for_url("http://koszek.tv")
    assert_equal @redir_resp_exp, http_code_for_url("http://koszek.org")
    assert_equal @redir_resp_exp, http_code_for_url("http://koszek.net")
  end

  def test_koszek_redirect_https
    #assert_equal @redir_resp_exp, http_code_for_url("https://koszek.co")
    assert_equal @redir_resp_exp, http_code_for_url("https://koszek.tv")
    #assert_equal @redir_resp_exp, http_code_for_url("https://koszek.org")
    #assert_equal @redir_resp_exp, http_code_for_url("https://koszek.net")
  end
end
