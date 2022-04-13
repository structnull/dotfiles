#VERSION: 1.0
#AUTHORS: mauricci

from helpers import retrieve_url
from helpers import download_file, retrieve_url
from novaprinter import prettyPrinter
import re

try:
    #python3
    from html.parser import HTMLParser
except ImportError:
    #python2
    from HTMLParser import HTMLParser
         
class cinecalidad(object):
    url = 'https://www.cinecalidad.to'
    name = 'CineCalidad'
    supported_categories = {'all': 'all'}
    
    class MyHTMLParser(HTMLParser):

        def __init__(self):
            HTMLParser.__init__(self)
            self.url = 'https://www.cinecalidad.to'
            self.insideDataDiv = False
            self.insideTitleDiv = False
            self.fullResData = []
            self.singleResData = self.getSingleData()
            
        def getSingleData(self):
            return {'name':'-1','seeds':'-1','leech':'-1','size':'-1','link':'-1','desc_link':'-1','engine_url':self.url}
        
        def handle_starttag(self, tag, attrs):
            Dict = dict(attrs)
            if tag == 'div' and Dict.get('id','') == 'content_inside':
                self.insideDataDiv = True
            if self.insideDataDiv and tag == 'div' and Dict.get('class','') == 'in_title':
                self.insideTitleDiv = True
            if self.insideDataDiv and tag == 'a' and len(attrs) > 0 and 'href' in Dict:
                self.singleResData['desc_link'] = Dict['href']
                self.singleResData['link'] = self.singleResData['desc_link']

        def handle_endtag(self, tag):
                self.insideTitleDiv = False
                if len(self.singleResData) > 0:
                    #ignore trash stuff
                    if self.singleResData['name'] != '-1':
                        prettyPrinter(self.singleResData)
                        self.fullResData.append(self.singleResData)
                    self.singleResData = self.getSingleData()

        def handle_data(self, data):
            if self.insideTitleDiv:
                self.singleResData['name'] = data.strip()

        def feed(self,html):
            HTMLParser.feed(self,html)
            self.insideDataDiv = False
            self.insideTitleDiv = False

    def download_torrent(self, info):
        html = retrieve_url(info)
        #first we retrive the link for the second page, then the magnet link
        torrPage2Link = re.search('(\/protect.+?)[\'\"]',html)
        if torrPage2Link and len(torrPage2Link.groups()) > 0:
            html2 = retrieve_url(self.url + torrPage2Link.group(1))
            magnet = re.search('(magnet\:\?.+?)[\'\"]',html2)
            if magnet and len(magnet.groups()) > 0:
                print(magnet.group(1) + ' '+ info)

    # DO NOT CHANGE the name and parameters of this function
    # This function will be the one called by nova2.py
    def search(self, what, cat='all'):
        currCat = self.supported_categories[cat]
        what = what.replace('%20','+')
        parser = self.MyHTMLParser()
        #analyze firt 10 pages
        for currPage in range(1,11):
            url = self.url+'/page/{1}/?s={0}'.format(what,currPage)
            #print(url)
            html = retrieve_url(url)
            parser.feed(html)
        #print(parser.fullResData)
        parser.close()

if __name__ == "__main__":
    c = cinecalidad()
    c.search('tomb%20raider')
