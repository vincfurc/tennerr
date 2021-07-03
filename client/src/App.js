import React from "react";
import {
  BrowserRouter as Router,
  Switch,
  Route,
} from "react-router-dom";
import Login from "./Login";
import About from "./About";
import {
  Link,
  HStack,
} from '@chakra-ui/react';
import FindFreelancers from "./FindFreelancers";
import MyAccount from "./MyAccount";
import ResolutionCenter from "./ResolutionCenter";
import RegisterSeller from "./RegisterSeller";

export default function App() {
  const linkData = [
    {
      text:'Home',
      url:'/'
    },
    {
      text:'Login',
      url:'/login'
    },
    {
      text:'My Account',
      url:'/my-account'
    },
    {
      text:'Register Seller',
      url:'/register-seller'
    },
    {
      text:'Find Freelancers',
      url:'/find-freelancers'
    },
    {
      text:'Resolution Center',
      url:'/resolution-center'
    }
  ];
  const links = linkData.map((link, idx) => {
    return (
    <Link href={link.url} key={idx}>{link.text}</Link>
    );
  });

  return (
      <div>
        <Router>
          <HStack spacing={8} alignItems={'center'}>
            <HStack
                as={'nav'}
                spacing={4}
                display={{ base: 'none', md: 'flex' }}>
              {links}
            </HStack>
          </HStack>
          {/* A <Switch> looks through its children <Route>s and
            renders the first one that matches the current URL. */}
          <Switch>
            <Route path="/login">
              <Login />
            </Route>
            <Route path="/my-account">
              <MyAccount/>
            </Route>
            <Route path="/register-seller">
              <RegisterSeller/>
            </Route>
            <Route path="/find-freelancers">
              <FindFreelancers/>
            </Route>
            <Route path="/resolution-center">
              <ResolutionCenter/>
            </Route>
            <Route path="/">
              <About />
            </Route>
          </Switch>
        </Router>
      </div>

  );
}
