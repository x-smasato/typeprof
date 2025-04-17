1 + 1 # This is fine

# This should show a type error
1 + "a"

# This should be ignored with tp-ignore
1 + "b" # tp-ignore

1 + "c"

# This should show a type error
1 + "d"
