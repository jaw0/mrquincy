# Generated by the protocol buffer compiler (protoc-perl) DO NOT EDIT!
# source: std_reply.proto



use strict;
use warnings;

use Google::ProtocolBuffers;
{
    unless (ACPStdReply->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'ACPStdReply',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_INT32(), 
                    'status_code', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'status_message', 2, undef
                ],

            ],
            undef,

            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

}
1;
