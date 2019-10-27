#!/usr/bin/python
# -*- coding: utf-8 -*-

class FilterModule(object):
    ''' greetings statement filter '''

    def filters(self):
        return {
            'host_location_statement': self.host_location_statement
        }

    def host_location_statement(self, data):
        return 'We are at ' + data + ' now.'
