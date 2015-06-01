#
# Cookbook Name:: delivery-cluster
# Library:: aws
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module DeliveryCluster
  module Provisioning
    # AWS class for AWS Provisioning Driver
    #
    # Specify all the methods a Provisioning Driver should implement
    # @author Salim Afiune <afiune@chef.io>
    class Aws < DeliveryCluster::Provisioning::Base
      attr_accessor :node
      attr_accessor :flavor
      attr_accessor :key_name
      attr_accessor :image_id
      attr_accessor :subnet_id
      attr_accessor :bootstrap_proxy
      attr_accessor :chef_config
      attr_accessor :ssh_username
      attr_accessor :security_group_ids
      attr_accessor :use_private_ip_for_ssh

      # Create a new Provisioning Driver Abstraction
      #
      # @param node [Chef::Node]
      def initialize(node)
        require 'chef/provisioning/aws_driver'

        fail "[#{driver}] Attributes not implemented (node['delivery-cluster'][#{driver}])" unless node['delivery-cluster'][driver]
        @node                   = node
        @flavor                 = @node['delivery-cluster'][driver]['flavor'] if @node['delivery-cluster'][driver]['flavor']
        @key_name               = @node['delivery-cluster'][driver]['key_name'] if @node['delivery-cluster'][driver]['key_name']
        @image_id               = @node['delivery-cluster'][driver]['image_id'] if @node['delivery-cluster'][driver]['image_id']
        @subnet_id              = @node['delivery-cluster'][driver]['subnet_id'] if @node['delivery-cluster'][driver]['subnet_id']
        @bootstrap_proxy        = @node['delivery-cluster'][driver]['bootstrap_proxy'] if @node['delivery-cluster'][driver]['bootstrap_proxy']
        @chef_config            = @node['delivery-cluster'][driver]['chef_config'] if @node['delivery-cluster'][driver]['chef_config']
        @ssh_username           = @node['delivery-cluster'][driver]['ssh_username'] if @node['delivery-cluster'][driver]['ssh_username']
        @security_group_ids     = @node['delivery-cluster'][driver]['security_group_ids'] if @node['delivery-cluster'][driver]['security_group_ids']
        @use_private_ip_for_ssh = false
        @use_private_ip_for_ssh = @node['delivery-cluster'][driver]['use_private_ip_for_ssh'] if @node['delivery-cluster'][driver]['use_private_ip_for_ssh']
      end

      # Return the machine options to use.
      #
      # @return [Hash] the machine_options for the specific driver
      def machine_options
        opts = {
          convergence_options: {
            bootstrap_proxy: @bootstrap_proxy,
            chef_config: @chef_config
          },
          bootstrap_options: {
            instance_type:      @flavor,
            key_name:           @key_name,
            security_group_ids: @security_group_ids
          },
          ssh_username:           @ssh_username,
          image_id:               @image_id,
          use_private_ip_for_ssh: @use_private_ip_for_ssh
        }

        # Add any optional machine options
        require 'chef/mixin/deep_merge'
        opts = Chef::Mixin::DeepMerge.hash_only_merge(opts, bootstrap_options: { subnet_id: @subnet_id }) if @subnet_id

        opts
      end

      # Create a array of machine_options specifics to a component
      #
      # @param component [String] component name
      # @param count [Integer] component number
      # @return [Array] specific machine_options for the specific component
      def specific_machine_options(component, _count = nil)
        return [] unless @node['delivery-cluster'][component]
        options = []
        options << { bootstrap_options: { instance_type: @node['delivery-cluster'][component]['flavor'] } } if @node['delivery-cluster'][component]['flavor']
        options << { bootstrap_options: { security_group_ids: @node['delivery-cluster'][component]['security_group_ids'] } } if @node['delivery-cluster'][component]['security_group_ids']
        options << { image_id: @node['delivery-cluster'][component]['image_id'] } if @node['delivery-cluster'][component]['image_id']
        # Specify more specific machine_options to add
        options
      end

      # Return the Provisioning Driver Name.
      #
      # @return [String] the provisioning driver name
      def driver
        'aws'
      end

      # Return the ipaddress from the machine.
      #
      # @param node [Chef::Node]
      # @return [String] an ipaddress
      def ipaddress(node)
        @use_private_ip_for_ssh ? node['ec2']['local_ipv4'] : node['ec2']['public_ipv4']
      end
    end
  end
end
