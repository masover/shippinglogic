require "builder"

module Shippinglogic
  class FedEx
    # Methods relating to building and sending a request to FedEx's web services.
    module Request
      private
        # Convenience method for sending requests to FedEx
        def request(body)
          real_class.post(base.url, :body => body)
        end
        
        # Convenience method to create a builder object so that our builder options are consistent across
        # the various services.
        #
        # Ex: if I want to change the indent level to 3 it should change for all requests built.
        def builder
          b = Builder::XmlMarkup.new(:indent => 2)
          b.instruct!
          b
        end
        
        # A convenience method for building the authentication block in your XML request
        def build_authentication(b)
          b.WebAuthenticationDetail do
            b.UserCredential do
              b.Key base.key
              b.Password base.password
            end
          end
          
          b.ClientDetail do
            b.AccountNumber base.account
            b.MeterNumber base.meter
          end
        end
        
        # A convenience method for building the version block in your XML request
        def build_version(b, service, major, intermediate, minor)
          b.Version do
            b.ServiceId service
            b.Major major
            b.Intermediate intermediate
            b.Minor minor
          end
        end
        
        # A convenience method for building the contact block in your XML request
        def build_contact(b, type)
          b.Contact do
            b.PersonName send("#{type}_name") if send("#{type}_name")
            b.Title send("#{type}_title") if send("#{type}_title")
            b.CompanyName send("#{type}_company_name") if send("#{type}_company_name")
            b.PhoneNumber send("#{type}_phone_number") if send("#{type}_phone_number")
            b.EMailAddress send("#{type}_email") if send("#{type}_email")
          end
        end
        
        # A convenience method for building the address block in your XML request
        def build_address(b, type)
          b.Address do
            if street_lines = send("#{type}_streets")
              street_lines.split("\n").each { |line| b.StreetLines line }
            end
            b.City send("#{type}_city") if send("#{type}_city")
            b.StateOrProvinceCode state_code(send("#{type}_state")) if send("#{type}_state")
            b.PostalCode send("#{type}_postal_code") if send("#{type}_postal_code")
            b.CountryCode country_code(send("#{type}_country")) if send("#{type}_country")
            b.Residential send("#{type}_residential")
          end
        end
        
        def build_insured_value(b)
          if insured_value
            b.TotalInsuredValue do
              b.Currency currency_type
              b.Amount insured_value
            end
          end
        end
        
        # A convenience method for building the package block in your XML request
        def build_package(b)
          b.PackageCount package_count
          
          b.RequestedPackages do
            b.SequenceNumber 1
            
            b.Weight do
              b.Units package_weight_units
              b.Value package_weight
            end
            
            if custom_packaging?
              b.Dimensions do
                b.Length package_length
                b.Width package_width
                b.Height package_height
                b.Units package_dimension_units
              end
            end
            
            if respond_to?(:signature) && signature
              self.special_services_requested << "SIGNATURE_OPTION"
            end
            
            if (respond_to?(:special_services_requested) && special_services_requested.any?)
              b.SpecialServicesRequested do
                if special_services_requested.any?
                  b.SpecialServiceTypes special_services_requested.join(",")
                end
              
                if signature
                  b.SignatureOptionDetail do
                    b.OptionType signature
                  end
                end
              end
            end
            
            if respond_to?(:customer_references) && customer_references
              customer_references.each do |type, value|
                b.CustomerReferences do
                  b.CustomerReferenceType type
                  b.Value value
                end
              end
            end
          end
        end
        
        def custom_packaging?
          packaging_type == "YOUR_PACKAGING"
        end
        
        def country_code(value)
          Enumerations::FEDEX_COUNTRY_CODES[value.to_s] || Enumerations::RAILS_COUNTRY_CODES[value.to_s] || value.to_s
        end
        
        def state_code(value)
          Enumerations::STATE_CODES[value.to_s] || value.to_s
        end
    end
  end
end