1 + 1 # This is fine

1 + "str" # This should show a type error

# typeprof:disable
1 + "str" # This should be ignored (block mode)
# typeprof:enable

1 + "str" # typeprof:disable

# typeprof:disable
1 + "str"  # This should be ignored (block mode)
1 + "str"  # This should be ignored (block mode)
# typeprof:enable

1 + "str"  # This should show a type error again
