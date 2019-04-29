require 'le'

# Now it would be global variable for whole application that's using this
# library.
LOGGER = Le.new('9cd92471-8243-4257-b74a-e5ec002a1353', local: Settings.development?)
