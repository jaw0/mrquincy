##
## This file was generated by Google::ProtocolBuffers (0.08)
## on Thu Jan  8 16:30:15 2015
##      
use strict;
use warnings;
use Google::ProtocolBuffers;
{       
    unless (ACPIPPort->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'ACPIPPort',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_FIXED32(), 
                    'ipv4', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_INT32(), 
                    'port', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'natdom', 3, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

}
1;
