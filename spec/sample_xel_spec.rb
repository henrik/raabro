
#
# specifying raabro
#
# Mon Sep 21 16:58:01 JST 2015
#

require 'spec_helper'


module Sample::Xel include Raabro

  # parser

  def pa(i); str(nil, i, '('); end
  def pz(i); str(nil, i, ')'); end
  def com(i); str(nil, i, ','); end

  def num(i); rex(:num, i, /-?[0-9]+/); end

  def args(i); eseq(:args, i, :pa, :exp, :com, :pz); end
  def funame(i); rex(:funame, i, /[A-Z][A-Z0-9]*/); end
  def fun(i); seq(:fun, i, :funame, :args); end

  def exp(i); alt(:exp, i, :fun, :num); end

  # entry point .parse

  def rewrite(tree)

    case tree.name
      when :exp
        rewrite tree.children.first
      when :num
        tree.string.to_i
      when :fun
        [ tree.children[0].string ] +
        tree.children[1].children.collect { |e| rewrite(e) }
      else
        fail ArgumentError.new("cannot rewrite #{tree.to_a.inspect}")
    end
  end

  def parse(input)

    t = all(nil, Raabro::Input.new(input, :prune => true), :exp)

    return nil if t.result != 1

    rewrite(t.children.first.shrink!)
  end
end


describe Raabro do

  describe Sample::Xel do

    describe '.funame' do

      it 'hits' do

        i = Raabro::Input.new('NADA')

        t = Sample::Xel.funame(i)

        expect(t.to_a(:leaves => true)).to eq(
          [ :funame, 1, 0, 4, nil, :rex, 'NADA' ]
        )
      end
    end

    describe '.fun' do

      it 'parses a function call' do

        i = Raabro::Input.new('SUM(1,MUL(4,5))', :prune => true)

        t = Sample::Xel.fun(i)

        expect(t.result).to eq(1)

        expect(
          Sample::Xel.rewrite(t.shrink!)
        ).to eq(
          [ 'SUM', 1, [ 'MUL', 4, 5 ] ]
        )
      end
    end

    describe '.parse' do

      it 'parses (success)' do

        expect(
          Sample::Xel.parse('MUL(7,-3)')
        ).to eq(
          [ 'MUL', 7, -3 ]
        )
      end

      it 'parses (miss)' do

        expect(Sample::Xel.parse('MUL(7,3) ')).to eq(nil)
        expect(Sample::Xel.parse('MUL(7,3')).to eq(nil)
      end
    end
  end
end
