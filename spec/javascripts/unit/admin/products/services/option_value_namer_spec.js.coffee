describe "OptionValueNamer", ->
  OptionValueNamer = null

  beforeEach ->
    module "ofn.admin"
    module "admin.products"
    module ($provide)->
      $provide.value "availableUnits", "g,kg,T,mL,L,kL"
      null

  beforeEach inject (_OptionValueNamer_) ->
    OptionValueNamer = _OptionValueNamer_

  describe "pluralize a variant unit name", ->
    namer = null
    beforeEach ->
      namer = new OptionValueNamer({})

    it "returns the same word if no plural is known", ->
      expect(namer.pluralize("foo", 2)).toEqual "foo"

    it "returns the same word if we omit the quantity", ->
      expect(namer.pluralize("loaf")).toEqual "loaf"

    it "finds the plural of a word", ->
      expect(namer.pluralize("loaf", 2)).toEqual "loaves"

    it "finds the singular of a word", ->
      expect(namer.pluralize("loaves", 1)).toEqual "loaf"

    it "finds the zero form of a word", ->
      expect(namer.pluralize("loaf", 0)).toEqual "loaves"

    it "ignores upper case", ->
      expect(namer.pluralize("Loaf", 2)).toEqual "loaves"

  describe "generating option value name", ->
    v = namer = null
    beforeEach ->
      v = {}
      namer = new OptionValueNamer(v)

    it "when description is blank", ->
      v.unit_description = null
      spyOn(namer, "value_scaled").and.returnValue true
      spyOn(namer, "option_value_value_unit").and.returnValue ["value", "unit"]
      expect(namer.name()).toBe "valueunit"

    it "when description is present", ->
      v.unit_description = 'desc'
      spyOn(namer, "option_value_value_unit").and.returnValue ["value", "unit"]
      spyOn(namer, "value_scaled").and.returnValue true
      expect(namer.name()).toBe "valueunit desc"

    it "when value is blank and description is present", ->
      v.unit_description = 'desc'
      spyOn(namer, "option_value_value_unit").and.returnValue [null, null]
      spyOn(namer, "value_scaled").and.returnValue true
      expect(namer.name()).toBe "desc"

    it "spaces value and unit when value is unscaled", ->
      v.unit_description = null
      spyOn(namer, "option_value_value_unit").and.returnValue ["value", "unit"]
      spyOn(namer, "value_scaled").and.returnValue false
      expect(namer.name()).toBe "value unit"

    describe "determining if a variant's value is scaled", ->
      v = namer = null

      beforeEach ->
        v = {}
        namer = new OptionValueNamer(v)

      it "returns true when the product has a scale", ->
        v.variant_unit_scale = 1000
        expect(namer.value_scaled()).toBe true

      it "returns false otherwise", ->
        expect(namer.value_scaled()).toBe false

    describe "generating option value's value and unit", ->
      v = namer = null

      beforeEach ->
        v = {}
        namer = new OptionValueNamer(v)

      it "generates simple values", ->
        v.variant_unit = 'weight'
        v.variant_unit_scale = 1.0
        v.unit_value = 100
        expect(namer.option_value_value_unit()).toEqual [100, 'g']

      it "generates values when unit value is non-integer", ->
        v.variant_unit = 'weight'
        v.variant_unit_scale = 1.0
        v.unit_value = 123.45
        expect(namer.option_value_value_unit()).toEqual [123.45, 'g']

      it "returns a value of 1 when unit value equals the scale", ->
        v.variant_unit = 'weight'
        v.variant_unit_scale = 1000.0
        v.unit_value = 1000.0
        expect(namer.option_value_value_unit()).toEqual [1, 'kg']

      it "generates values for all weight scales", ->
        for units in [[1.0, 'g'], [1000.0, 'kg'], [1000000.0, 'T']]
          [scale, unit] = units
          v.variant_unit = 'weight'
          v.variant_unit_scale = scale
          v.unit_value = 100 * scale
          expect(namer.option_value_value_unit()).toEqual [100, unit]

      it "generates values for all volume scales", ->
        for units in [[0.001, 'mL'], [1.0, 'L'], [1000.0, 'kL']]
          [scale, unit] = units
          v.variant_unit = 'volume'
          v.variant_unit_scale = scale
          v.unit_value = 100 * scale
          expect(namer.option_value_value_unit()).toEqual [100, unit]

      it "generates right values for volume with rounded values", ->
        unit = 'L'
        v.variant_unit = 'volume'
        v.variant_unit_scale = 1.0
        v.unit_value = 0.7
        expect(namer.option_value_value_unit()).toEqual [700, 'mL']

      it "chooses the correct scale when value is very small", ->
        v.variant_unit = 'volume'
        v.variant_unit_scale = 0.001
        v.unit_value = 0.0001
        expect(namer.option_value_value_unit()).toEqual [0.1, 'mL']

      it "generates values for item units", ->
        #TODO
        # %w(packet box).each do |unit|
        #   p = double(:product, variant_unit: 'items', variant_unit_scale: nil, variant_unit_name: unit)
        #   v.stub(:product) { p }
        #   v.stub(:unit_value) { 100 }
        #   subject.option_value_value_unit.should == [100, unit.pluralize]

      it "generates singular values for item units when value is 1", ->
        v.variant_unit = 'items'
        v.variant_unit_scale = null
        v.variant_unit_name = 'packet'
        v.unit_value = 1
        expect(namer.option_value_value_unit()).toEqual [1, 'packet']

      it "returns [nil, nil] when unit value is not set", ->
        v.variant_unit = 'items'
        v.variant_unit_scale = null
        v.variant_unit_name = 'foo'
        v.unit_value = null
        expect(namer.option_value_value_unit()).toEqual [null, null]

