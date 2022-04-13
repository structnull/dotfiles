#VERSION: 1.03
#AUTHORS: iordic (iordicdev@gmail.com)


from helpers import download_file, retrieve_url
from novaprinter import prettyPrinter
import re

class elitetorrent(object):
    url = 'https://www.elitetorrent.com'
    name = 'Elitetorrent'
    # Page has only movies and tv series. Search box has no filters
    supported_categories = {'all': '0', 'movies': 'peliculas', 'tv': 'series'}

    def __init__(self):
        self.pages_limit = 2     # Limit of pages, more pages increase the time it takes

    def download_torrent(self, info):
        """ Unused :( """
        print(download_file(info))

    def search(self, what, cat='all'):
        search_url = "{}/?s={}".format(self.url, what.replace('%20', '+'))
        html = retrieve_url(search_url)

        # Get number of pages
        if "paginacion" in html:
            pages = re.findall(r'<a.*?class="pagina.*?</a>', html)
            if len(pages) > 0:
                last_page = pages[-1]
                last_page = re.findall(r'page/.*?/', last_page)[0]
                last_page = last_page.replace('/', '').replace('page', '')
                number_pages = int(last_page)

        # Only one page but there are results
        elif "Resultado de buscar" in html:
            number_pages = 1
        else:
            # A little trick to avoid entering the pages loop
            number_pages = 0

        # Set number of pages depending by limit
        number_pages = number_pages if number_pages < self.pages_limit else self.pages_limit

        links = []
        
        for page in range(1, number_pages + 1):
            # Each page's url looks like: https://www.example.com/page/[1-9]*/?s=WHAT
            url = "{}/page/{}/?s={}".format(self.url, page, what.replace('%20', '+'))
            html = retrieve_url(url).replace('\n','')   # Replace newline to help the regex
            # I hate regex, check if selected category is films or tv, if its 'all' get both
            pattern = r'({0}/series/.*?/|{0}/peliculas/.*?/)'.format(self.url) if cat == "all" \
                        else r'{0}/{1}/.*?/'.format(self.url, self.supported_categories[cat])
            # Get all ocurrencies
            items = re.findall(pattern, html)
            links = links + items
            links = list(dict.fromkeys(links))  # Remove duplicated items (w3schools <3)

        for i in links:
            # Visiting individual results to get its attributes makes it so slow
            data = retrieve_url(i).replace('\n','')
            item = {}
            pattern = r'({0}/wp-content/lazy/js/.+.js)'.format(self.url)
            js_file = re.findall(pattern, data)[0]
            obfuscated = retrieve_url(js_file)
            pattern = r'(\'[a-z0-9]+\',\'[a-z0-9]+\',\'[a-z0-9]+\',\'[a-z0-9]+\')'  # base36 letter caps
            for j in range(3):  # its encoded iterated 3 times            
                obfuscated = re.findall(pattern, obfuscated)[0]
                obfuscated = obfuscated.replace("'","").split(",")
                (a,b,c) = obfuscated[:-1]
                obfuscated = self.deobfuscate(a,b,c)

            # Can't obtain info about leechers and seaders
            item['seeds'] = '-1'
            item['leech'] = '-1'
            # re.match().group(0) didn't work for me 
            item['size'] = re.findall(r'o:</b>.*?Bs', data)[0].lstrip("o:</b>") \
                            .rstrip("s").strip()
            item['link'] = re.findall(r'\'magnet:.*?\'', obfuscated)[0].replace("'","")
            item['desc_link'] = i
            item['name'] = item['desc_link'].rstrip('/').split("/")[-1] # lazy but works
            item['engine_url'] = self.url
            # Prints in this format: link|name|size|seeds|leech|engine_url|desc_link
            prettyPrinter(item)

    def deobfuscate(self, a, b, c):
        """Deobfuscate Elitetorrent encodings.
           Copied and cleaned code from its own js file.
           Stupid transpositions and stupid encodings. :D
        """
        i = 0;
        text = []
        key = []

        # Condition to loop over all items from a, b & c
        while (len(text) + len(key)) != (len(a) + len(b) + len(c)):
            if i < 5:              # Conversion is like:
                key.append(a[i])   # | a b c d e |
                key.append(b[i])   # | f g h i j | => |a f k b g l c h m d i n e j o|
                key.append(c[i])   # | k l m n o |
            else:
                if i < len(a):          # The same conversion but rows has different sizes
                    text.append(a[i])   # Example:
                if i < len(b):          # | a b c d e f |
                    text.append(b[i])   # | g h i j     | => |a g k b h l c i d j e f|
                if i < len(c):          # | k l         |
                    text.append(c[i])
            i+=1

        # First 3 strings converted to 2 :)
        text = ''.join(text)
        key = ''.join(key)

        # And this 2 strings will be converted to 1 :/
        result = []
        j = 0

        for i in range(0, len(text), 2):
            x = 1 if ord(key[j]) % 2 else -1    # check if ascii value of key[j] is even
            result.append(chr(int(text[i:i+2], 36) - x)) # Conversions: char <- int <- base36
            j+=1
            if j >= len(key):
                j = 0   # Reset position, key is shorter than text
        return ''.join(result)  # Convert array to string


