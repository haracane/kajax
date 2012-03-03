require 'spec_helper'

# rspec -c spec/keyword_alias_util_spec.rb

describe KeywordAliasUtil do
  describe "normalize_text" do
    it "should normalize number" do
      KeywordAliasUtil.normalize_text("渋谷１０９").should == '渋谷109'
    end
    it "should normalize alphabet" do
      KeywordAliasUtil.normalize_text("ＡＫＢ48").should == 'akb48'
    end
    it "should normalize symbol" do
      KeywordAliasUtil.normalize_text("記号＠＋＊；：＜＞？＿、。／！＃＄％＆＝～｜＾￥").should == '記号@+*;:<>?_,./!#$%&=~|^\\'
    end
    it "should normalize bracket" do
      KeywordAliasUtil.normalize_text("（a）「b」(c){d}[e]").should == '(a)(b)(c)(d)(e)'
    end
    it "should normalize hyphen" do
      KeywordAliasUtil.normalize_text("1ー‐－-6").should == '1ー‐--6'
    end
    it "should normalize quote" do
      KeywordAliasUtil.normalize_text("”’‘“\"'`").should == "'''''''"
    end
    it "should normalize hankaku katakana quote" do
      KeywordAliasUtil.normalize_text("半角ｶﾅ").should == '半角カナ'
    end
    it "should normalize hankaku small kana quote" do
      KeywordAliasUtil.normalize_text("キャノン").should == 'キヤノン'
    end
    it "should delete space" do
      KeywordAliasUtil.normalize_text("NTT Communications　Forum\t2011@帝国ホテル").should == 'nttcommunicationsforum2011@帝国ホテル'
    end
  end
end
