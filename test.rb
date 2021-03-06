#!/usr/bin/env ruby
# Copyright (c) 2017 Wojciech Adam Koszek <wojciech@koszek.com>

# This file is a unit-test for the website. I use it to make sure my
# infrastructure configuration has been deployed correctly. Basically
# I try to make sure that domains which are under my control are properly
# showing my main website.

require 'minitest/autorun'
require 'net/http'

require 'pp'
require 'json'
require 'socket'
require 'openssl'
require 'resolv'

# TODO: add a simple 80 connect (to see if nginx is listening)
# TODO: add a simple 443 connect
# TODO: add a gzip test to make sure compression is enabled
# TODO: add a test for DNS records: SPF, DKIM etc.
# TODO: add a test for caching -- add 1 non-caching asset

class TestMeme < Minitest::Test
  def setup
    @domain_main = "koszek.com";
    @main_url_str = "https://www.#{@domain_main}/"
    @redir_resp_exp = [301, @main_url_str ];
    @supported_domains = [ "koszek.co", "koszek.tv", "koszek.us", "koszek.org", "koszek.net"]
    @dns_servers = [ "ns41.domaincontrol.com", "ns42.domaincontrol.com" ]
    @mxes = [ [10, "mx.zoho.com"], [20, "mx2.zoho.com"]]
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
  
  def http_get_response(url_str)
    uri = URI(url_str)
    use_ssl = (url_str =~ /^https/)
    response = Net::HTTP.start(uri.host, uri.port, :use_ssl => use_ssl) do |http|
      req = Net::HTTP::Get.new uri
      http.request(req) # Net::HTTPResponse object
    end
  end

  def http_code_for_url(url_str)
    response = http_get_response(url_str)

    http_response_debug(response)

    return [ response.code.to_i, response['Location']]
  end

  def test_koszek_redirect_http
    @supported_domains.each do |domain|
      assert_equal @redir_resp_exp, http_code_for_url("http://#{domain}")
      assert_equal @redir_resp_exp, http_code_for_url("http://www.#{domain}")
    end
  end

  def test_koszek_redirect_https
    @supported_domains.each do |domain|
      assert_equal @redir_resp_exp, http_code_for_url("https://#{domain}")
      assert_equal @redir_resp_exp, http_code_for_url("http://www.#{domain}")
    end
  end

  def ssl_get_info(domain)
    tcp_client = TCPSocket.new(domain, 443)
    ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client)
    ssl_client.connect
    cert = OpenSSL::X509::Certificate.new(ssl_client.peer_cert)
    ssl_client.sysclose
    tcp_client.close
    issuer = OpenSSL::X509::Name.new(cert.subject).to_a[0]
    cert_domain = issuer[1]
    certprops = OpenSSL::X509::Name.new(cert.issuer).to_a
    issuer = certprops.select { |name, data, type| name == "O" }.first[1]

    return {
      :domain => cert_domain,
      :not_before => cert.not_before,
      :not_after => cert.not_after,
      :issuer => issuer
    }
  end

  def test_ssl_domain
    @supported_domains.each do |supp_domain|
      info = ssl_get_info(supp_domain)
      assert_equal info[:domain], @domain_main
    end
  end

  def test_ssl_cert_date
    @supported_domains.each do |supp_domain|
      info = ssl_get_info(supp_domain)
      time_cur = Time.new()
      assert_equal time_cur > info[:not_before], true
      assert_equal time_cur < info[:not_after], true
    end
  end

  # DNS
  def test_dns_ns
    dns = Resolv::DNS.open
    records = dns.getresources(@domain_main, Resolv::DNS::Resource::IN::NS)
    assert_operator records, :!=, nil
    cur_dns_servers = records.map {|record| record.name.to_s }.sort
    assert_equal @dns_servers, cur_dns_servers
  end

  def test_dns_ns
    dns = Resolv::DNS.open
    records = dns.getresources(@domain_main, Resolv::DNS::Resource::IN::NS)
    assert_operator records, :!=, nil
    cur_dns_servers = records.map {|record| record.name.to_s }.sort
    assert_equal @dns_servers.sort(), cur_dns_servers.sort()
  end

  def test_dns_mx
    dns = Resolv::DNS.open
    records = dns.getresources(@domain_main, Resolv::DNS::Resource::IN::MX)
    cur_mxes = records.map {|record| [ record.preference, record.exchange.to_s ] }
    assert_equal @mxes.sort(), cur_mxes.sort()
  end
 
  def http_resp_to_headers(resp)
    hdrs = {}
    resp.each_header {|k,v| hdrs[k] = v }
    return hdrs
  end

  # Keep-alive
  def test_keepalive
    resp = http_get_response(@main_url_str + "/img/favicon.ico")
    hdrs = http_resp_to_headers(resp)
    assert_includes hdrs, "connection", "expected to have connection"
    assert_operator hdrs['connection'], :==, 'keep-alive'
  end

  # Caching
  def test_caching
    resp = http_get_response(@main_url_str + "/img/favicon.ico")
    hdrs = http_resp_to_headers(resp)
    pp hdrs
    # ETag: "58b29b5e-5823"
    # Expires: Thu, 01 Jan 1970 00:00:01 GMT
    # Cache-Control: no-cache
    assert_includes hdrs, "etag", "expected ETag set"
    assert_includes hdrs, "expires", "expected Expires set"
    assert_includes hdrs, "cache-control", "expected Cache-Control"
    assert_operator hdrs['cache-control'], :!=, 'no-cache' 
  end

  # HTTP/2 tests
  def test_http2
    return
    req, resp = get_http_headers("https://www.koszek.com")
    pp req
    pp resp
  end

  def get_http_headers(domain)
    out = `/usr/local/opt/curl/bin/curl --stderr - --head --http2 -v #{domain}`
    raw_req_lines  = out.split("\n").select {|tmp_line| tmp_line =~ /^> .*:.*/ }
    raw_resp_lines = out.split("\n").select {|tmp_line| tmp_line =~ /^< .*:.*/ }
    req_lines = http_headers_to_dict(raw_req_lines)
    resp_lines = http_headers_to_dict(raw_resp_lines)
    return req_lines, resp_lines
  end

  def http_headers_to_dict(raw_headers)
    hdrs = {}
    raw_headers.map { |a|
      hdrname, hdrval = a.split(":")
      hdrname.gsub!(/^> /, '')
      hdrname.gsub!(/^< /, '')
      [ hdrname.strip, hdrval.strip ]
    }.each { |hdrname, hdrval|
      hdrs[hdrname] = hdrval
    }
    return hdrs
  end
end
