#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging


LOG_LEVELS = [logging.DEBUG, logging.INFO, logging.WARNING, logging.ERROR,
              logging.CRITICAL]
LOG_LEVEL_NAMES = [logging.getLevelName(lvl) for lvl in LOG_LEVELS]


def get_log_level_value(log_level_name):
    log_level_value = next(
        (lvl for lvl in LOG_LEVELS
         if logging.getLevelName(lvl) == log_level_name),
        None
    )

    if log_level_value is None:
        raise ValueError('Unknown log level: ' + log_level_name)
    else:
        return log_level_value


def setup(log_level_name):
    log_level_name = strip_quotes(log_level_name)

    log_level_value = next(
        (lvl for lvl in LOG_LEVELS
         if logging.getLevelName(lvl) == log_level_name),
        None
    )

    if log_level_value is None:
        raise ValueError('Unknown log level: ' + log_level_name)

    logging.basicConfig(
        datefmt='%Y-%m-%dT%H:%M:%S%z',
        format='%(asctime)s %(levelname)s [%(name)s.%(funcName)s:%(lineno)d] %(message)s',  # noqa: E501
        level=log_level_value
    )


def strip_quotes(s):
    if len(s) >= 2 and s[0] == '"' and s[-1] == '"':
        return s[1:-1]
    else:
        return s
