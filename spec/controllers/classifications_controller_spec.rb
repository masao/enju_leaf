require 'spec_helper'

describe ClassificationsController do
  fixtures :all

  describe "GET index" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in Factory(:admin)
      end

      it "assigns all classifications as @classifications" do
        get :index
        assigns(:classifications).should_not be_empty
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in Factory(:librarian)
      end

      it "assigns all classifications as @classifications" do
        get :index
        assigns(:classifications).should_not be_empty
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in Factory(:user)
      end

      it "assigns all classifications as @classifications" do
        get :index
        assigns(:classifications).should_not be_empty
      end
    end

    describe "When not logged in" do
      it "assigns all classifications as @classifications" do
        get :index
        assigns(:classifications).should_not be_empty
      end
    end
  end

  describe "GET show" do
    before(:each) do
      @classification = Factory(:classification)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in Factory(:admin)
      end

      it "assigns the requested classification as @classification" do
        get :show, :id => @classification.id
        assigns(:classification).should eq(@classification)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in Factory(:librarian)
      end

      it "assigns the requested classification as @classification" do
        get :show, :id => @classification.id
        assigns(:classification).should eq(@classification)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in Factory(:user)
      end

      it "assigns the requested classification as @classification" do
        get :show, :id => @classification.id
        assigns(:classification).should eq(@classification)
      end
    end

    describe "When not logged in" do
      it "assigns the requested classification as @classification" do
        get :show, :id => @classification.id
        assigns(:classification).should eq(@classification)
      end
    end
  end

  describe "GET new" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in Factory(:admin)
      end

      it "assigns the requested classification as @classification" do
        get :new
        assigns(:classification).should_not be_valid
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in Factory(:librarian)
      end

      it "assigns the requested classification as @classification" do
        get :new
        assigns(:classification).should_not be_valid
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in Factory(:user)
      end

      it "should assign the requested classification as @classification" do
        get :new
        assigns(:classification).should_not be_valid
      end
    end

    describe "When not logged in" do
      it "should not assign the requested classification as @classification" do
        get :new
        assigns(:classification).should_not be_valid
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET edit" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in Factory(:admin)
      end

      it "assigns the requested classification as @classification" do
        classification = Factory.create(:classification)
        get :edit, :id => classification.id
        assigns(:classification).should eq(classification)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in Factory(:librarian)
      end

      it "assigns the requested classification as @classification" do
        classification = Factory.create(:classification)
        get :edit, :id => classification.id
        assigns(:classification).should eq(classification)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in Factory(:user)
      end

      it "assigns the requested classification as @classification" do
        classification = Factory.create(:classification)
        get :edit, :id => classification.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested classification as @classification" do
        classification = Factory.create(:classification)
        get :edit, :id => classification.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "POST create" do
    before(:each) do
      @attrs = Factory.attributes_for(:classification)
      @invalid_attrs = {:category => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in Factory(:admin)
      end

      describe "with valid params" do
        it "assigns a newly created classification as @classification" do
          post :create, :classification => @attrs
          assigns(:classification).should be_valid
        end

        it "redirects to the created classification" do
          post :create, :classification => @attrs
          response.should redirect_to(classification_url(assigns(:classification)))
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved classification as @classification" do
          post :create, :classification => @invalid_attrs
          assigns(:classification).should_not be_valid
        end

        it "re-renders the 'new' template" do
          post :create, :classification => @invalid_attrs
          response.should render_template("new")
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in Factory(:librarian)
      end

      describe "with valid params" do
        it "assigns a newly created classification as @classification" do
          post :create, :classification => @attrs
          assigns(:classification).should be_valid
        end

        it "should be forbidden" do
          post :create, :classification => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved classification as @classification" do
          post :create, :classification => @invalid_attrs
          assigns(:classification).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :classification => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in Factory(:user)
      end

      describe "with valid params" do
        it "assigns a newly created classification as @classification" do
          post :create, :classification => @attrs
          assigns(:classification).should be_valid
        end

        it "should be forbidden" do
          post :create, :classification => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved classification as @classification" do
          post :create, :classification => @invalid_attrs
          assigns(:classification).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :classification => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "assigns a newly created classification as @classification" do
          post :create, :classification => @attrs
          assigns(:classification).should be_valid
        end

        it "should be forbidden" do
          post :create, :classification => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved classification as @classification" do
          post :create, :classification => @invalid_attrs
          assigns(:classification).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :classification => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "PUT update" do
    before(:each) do
      @classification = Factory(:classification)
      @attrs = Factory.attributes_for(:classification)
      @invalid_attrs = {:category => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in Factory(:admin)
      end

      describe "with valid params" do
        it "updates the requested classification" do
          put :update, :id => @classification.id, :classification => @attrs
        end

        it "assigns the requested classification as @classification" do
          put :update, :id => @classification.id, :classification => @attrs
          assigns(:classification).should eq(@classification)
        end
      end

      describe "with invalid params" do
        it "assigns the requested classification as @classification" do
          put :update, :id => @classification.id, :classification => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in Factory(:librarian)
      end

      describe "with valid params" do
        it "updates the requested classification" do
          put :update, :id => @classification.id, :classification => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @classification.id, :classification => @attrs
          assigns(:classification).should eq(@classification)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "should be forbidden" do
          put :update, :id => @classification, :classification => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in Factory(:user)
      end

      describe "with valid params" do
        it "updates the requested classification" do
          put :update, :id => @classification.id, :classification => @attrs
        end

        it "assigns the requested classification as @classification" do
          put :update, :id => @classification.id, :classification => @attrs
          assigns(:classification).should eq(@classification)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested classification as @classification" do
          put :update, :id => @classification.id, :classification => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "updates the requested classification" do
          put :update, :id => @classification.id, :classification => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @classification.id, :classification => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested classification as @classification" do
          put :update, :id => @classification.id, :classification => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "DELETE destroy" do
    before(:each) do
      @classification = Factory(:classification)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in Factory(:admin)
      end

      it "destroys the requested classification" do
        delete :destroy, :id => @classification.id
      end

      it "redirects to the classifications list" do
        delete :destroy, :id => @classification.id
        response.should redirect_to(classifications_url)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in Factory(:librarian)
      end

      it "destroys the requested classification" do
        delete :destroy, :id => @classification.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @classification.id
        response.should be_forbidden
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in Factory(:user)
      end

      it "destroys the requested classification" do
        delete :destroy, :id => @classification.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @classification.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "destroys the requested classification" do
        delete :destroy, :id => @classification.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @classification.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end
end