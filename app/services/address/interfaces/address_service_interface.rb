module Address
  module Interfaces
    class AddressServiceInterface
      def address_lookup(address)
        raise NotImplementedError, "address_lookup method must be implemented."
      end
    end
  end
end
