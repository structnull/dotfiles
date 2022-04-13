#VERSION: 0.13
#AUTHORS: Bugsbringer (dastins193@gmail.com)


SITE_URL = 'https://darklibria.it/'


import logging
import os
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from html.parser import HTMLParser
from math import ceil
from re import compile as re_compile
from time import mktime
from urllib import parse

from helpers import retrieve_url
from novaprinter import prettyPrinter

LOG_FORMAT = '[%(asctime)s] %(levelname)s:%(name)s:%(funcName)s - %(message)s'
LOG_DT_FORMAT = '%d-%b-%y %H:%M:%S'


class darklibria:
    url = SITE_URL
    name = 'dark-libria'
    supported_categories = {'all': '0'}

    units_dict = {"Тб": "TB", "Гб": "GB", "Мб": "MB", "Кб": "KB", "б": "B"}
    page_search_url_pattern = SITE_URL + 'search?page={page}&find={what}'
    dt_regex = re_compile('\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}')

    def __init__(self, output=True):
        self.output = output

    def search(self, what, cat='all'):
        self.torrents_count = 0
        what = parse.quote(parse.unquote(what))
        logger.info(parse.unquote(what))
        self.set_search_data(self.handle_page(what, 1))
        with ThreadPoolExecutor() as executor:
            for page in range(2, self.pages_count + 1):
                executor.submit(self.handle_page, what, page)
        logger.info('%s torrents', self.torrents_count)

    def handle_page(self, what, page):
        url = self.page_search_url_pattern.format(page=page, what=what)
        data = self.request_get(url)
        if not data:
            return
        parser = Parser(data)
        serials = parser.find_all('tbody', {'style': 'vertical-align: center'})
        with ThreadPoolExecutor() as executor:
            for serial in serials:
                executor.submit(self.handle_serial, serial.a['href'])
        return parser

    def handle_serial(self, url):
        data = self.request_get(url)
        if not data:
            return
        parser = Parser(data)
        name = parser.find(attrs={'id': 'russian_name'}).text
        for torrent_row in parser.find_all('tr', {'class': 'torrent'}):
            self.handle_torrent_row(torrent_row, name, url)

    def handle_torrent_row(self, torrent_row, name, url):
        type, quality, size_data, date_time, download, seeds, leech, *_ = torrent_row.children
        self.pretty_printer({
            'link': self.get_link(download),
            'name': self.get_name(name, quality, type, date_time),
            'size': self.get_size(size_data),
            'seeds': int(seeds.text),
            'leech': int(leech.text),
            'engine_url': self.url,
            'desc_link': url
        })
        self.torrents_count += 1

    def get_link(self, download):
        return download.find(attrs={'title': 'Magnet-ссылка'})['href'] \
            or download.find(attrs={'title': 'Скачать торрент'})['href']
            
    def get_name(self, name, quality, type, date_time):
        return '[{}] {} [{}] {}'.format(
            self.get_date(date_time),
            name,
            type.text,
            quality.text
        )

    def get_date(self, date_time):
        utc_dt_string = self.dt_regex.search(date_time.text).group()
        utc = datetime.strptime(utc_dt_string, '%Y-%m-%d %H:%M:%S')
        return str(utc2local(utc))

    def get_size(self, size_data):
        size, unit = size_data.text.split()
        return size + ' ' + self.units_dict[unit]

    def request_get(self, url):
        try:
            return retrieve_url(url)
        except Exception as exp:
            logger.error(exp)
            self.pretty_printer({
                'link': 'Error',
                'name': 'Connection failed',
                'size': "0",
                'seeds': -1,
                'leech': -1,
                'engine_url': self.url,
                'desc_link': self.url
            })

    def pretty_printer(self, dictionary):
        logger.debug(str(dictionary))
        if self.output:
            prettyPrinter(dictionary)

    def set_search_data(self, parser):
        results = parser.find('span', {'class': 'text text-light mt-0'})
        if results:
            parts = results.text.split()
            items_count = int(parts[4])
            items_on_page = int(parts[2].split('-')[1])
            self.pages_count = ceil(items_count / items_on_page)

            logger.info('%s animes', items_count)
        else:
            self.pages_count = 0

        logger.info('%s pages', self.pages_count)


class Tag:
    def __init__(self, tag=None, attrs=(), is_self_closing=None):
        self.type = tag
        self.is_self_closing = is_self_closing
        self._attrs = tuple(attrs)
        self._content = tuple()

    @property
    def attrs(self):
        """returns dict of Tag's attrs"""
        return dict(self._attrs)

    @property
    def text(self):
        """returns str of all contained text"""
        return ''.join(c if isinstance(c, str) else c.text for c in self._content)

    def _add_content(self, obj):
        if isinstance(obj, (Tag, str)):
            self._content += (obj,)
        else:
            raise TypeError('Argument must be str or %s, not %s' %
                            (self.__class__, obj.__class__))

    def find(self, tag=None, attrs=None):
        """returns Tag or None"""
        return next(self._find_all(tag, attrs), None)

    def find_all(self, tag=None, attrs=None):
        """returns list"""
        return list(self._find_all(tag, attrs))

    def _find_all(self, tag_type=None, attrs=None):
        """returns generator"""
        if not (isinstance(tag_type, (str, Tag)) or tag_type is None):
            raise TypeError(
                'tag_type argument must be str or Tag, not %s' % (tag_type.__class__))

        if not (isinstance(attrs, dict) or attrs is None):
            raise TypeError('attrs argument must be dict, not %s' %
                            (self.__class__))

        # get tags-descendants generator
        results = self.descendants

        # filter by Tag.type
        if tag_type:
            if isinstance(tag_type, Tag):
                tag_type, attrs = tag_type.type, (
                    attrs if attrs else tag_type.attrs)

            results = filter(lambda t: t.type == tag_type, results)

        # filter by Tag.attrs
        if attrs:
            # remove Tags without attrs
            results = filter(lambda t: t._attrs, results)

            def filter_func(tag):
                for key in attrs.keys():
                    if attrs[key] not in tag.attrs.get(key, ()):
                        return False
                return True

            # filter by attrs
            results = filter(filter_func, results)

        yield from results

    @property
    def children(self):
        """returns generator of tags-children"""
        return (obj for obj in self._content if isinstance(obj, Tag))

    @property
    def descendants(self):
        """returns generator of tags-descendants"""
        for child_tag in self.children:
            yield child_tag
            yield from child_tag.descendants

    def __getitem__(self, key):
        return self.attrs[key]

    def __getattr__(self, attr):
        if not attr.startswith("__"):
            return self.find(tag=attr)

    def __repr__(self):
        attrs = ' '.join(str(k) if v is None else '{}="{}"'.format(k, v)
                         for k, v in self._attrs)
        starttag = ' '.join((self.type, attrs)) if attrs else self.type

        if self.is_self_closing:
            return '<{starttag}>\n'.format(starttag=starttag)
        else:
            nested = '\n' * bool(next(self.children, None)) + \
                ''.join(map(str, self._content))
            return '<{}>{}</{}>\n'.format(starttag, nested, self.type)


class Parser(HTMLParser):
    def __init__(self, html_code, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self._root = Tag('_root')
        self._path = [self._root]

        self.feed(''.join(map(str.strip, html_code.splitlines())))
        self.handle_endtag(self._root.type)
        self.close()

        self.find = self._root.find
        self.find_all = self._root.find_all

    @property
    def attrs(self):
        return self._root.attrs

    @property
    def text(self):
        return self._root.text

    def handle_starttag(self, tag, attrs):
        self._path.append(Tag(tag=tag, attrs=attrs))

    def handle_endtag(self, tag_type):
        for pos, tag in tuple(enumerate(self._path))[::-1]:
            if isinstance(tag, Tag) and tag.type == tag_type and tag.is_self_closing is None:
                tag.is_self_closing = False

                for obj in self._path[pos + 1:]:
                    if isinstance(obj, Tag) and obj.is_self_closing is None:
                        obj.is_self_closing = True

                    tag._add_content(obj)

                self._path = self._path[:pos + 1]

                break

    def handle_startendtag(self, tag, attrs):
        self._path.append(Tag(tag=tag, attrs=attrs, is_self_closing=True))

    def handle_decl(self, decl):
        self._path.append(Tag(tag='!'+decl, is_self_closing=True))

    def handle_data(self, text):
        self._path.append(text)

    def __getitem__(self, key):
        return self.attrs[key]

    def __getattr__(self, attr):
        if not attr.startswith("__"):
            return getattr(self._root, attr)

    def __repr__(self):
        return ''.join(str(c) for c in self._root._content)


def utc2local(utc):
    epoch = mktime(utc.timetuple())
    offset = datetime.fromtimestamp(epoch) - datetime.utcfromtimestamp(epoch)
    return utc + offset


is_main = __name__ == '__main__'
STORAGE = os.path.abspath(os.path.dirname(__file__))
log_config = {
    'level': logging.INFO if is_main else logging.WARNING,
    'filename': None if is_main else os.path.join(STORAGE, 'darklibria.log'),
    'format': LOG_FORMAT,
    'datefmt': LOG_DT_FORMAT
}
logging.basicConfig(**log_config)
logger = logging.getLogger('darklibria')

if is_main:
    import sys
    darklibria(output=False).search(sys.argv[-1])
