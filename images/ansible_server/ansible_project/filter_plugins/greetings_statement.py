#!/usr/bin/python
# -*- coding: utf-8 -*-

class FilterModule(object):
    ''' greetings statement filter '''

    def filters(self):
        return {
            'greetings_statement': self.greetings_statement
        }

    def greetings_statement(self, data):
        return 'Hello ' + data + ', it is nice to meet you.'
