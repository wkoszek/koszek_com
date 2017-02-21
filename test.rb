#!/usr/bin/env ruby
# Copyright (c) 2017 Wojciech Adam Koszek <wojciech@koszek.com>

# This file is a unit-test for the website. I use it to make sure my
# infrastructure configuration has been deployed correctly. Basically
# I try to make sure that domains which are under my control are properly
# showing my main website.

require 'minitest/autorun'
require 'net/http'

class TestMeme < Minitest::Test
  def setup
    @redir_resp_exp = [301, "https://www.koszek.com/"]
    @debug = 0
  end

  def http_response_debug(response)
    if @debug < 1 then
      return
    end
    case response
    when Net::HTTPSuccess then
      print "# success"
      response
    when Net::HTTPRedirection then
      location = response['location']
      warn "# redirected to #{location}"
    else
      response.value
    end
  end

  def http_code_for_url(url_str)
    uri = URI(url_str)
    use_ssl = (url_str =~ /^https/)
    response = Net::HTTP.start(uri.host, uri.port, :use_ssl => use_ssl) do |http|
      req = Net::HTTP::Get.new uri
      http.request(req) # Net::HTTPResponse object
    end

    http_response_debug(response)

    return [ response.code.to_i, response['Location']]
  end

  def test_koszek_redirect_http
    assert_equal @redir_resp_exp, http_code_for_url("http://koszek.co")
    assert_equal @redir_resp_exp, http_code_for_url("http://koszek.tv")
    assert_equal @redir_resp_exp, http_code_for_url("http://koszek.org")
    assert_equal @redir_resp_exp, http_code_for_url("http://koszek.net")
  end

  def test_koszek_redirect_https
    assert_equal @redir_resp_exp, http_code_for_url("https://koszek.co")
    assert_equal @redir_resp_exp, http_code_for_url("https://koszek.tv")
    assert_equal @redir_resp_exp, http_code_for_url("https://koszek.org")
    assert_equal @redir_resp_exp, http_code_for_url("https://koszek.net")
  end
end
