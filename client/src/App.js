import React from "react";
import {
  BrowserRouter as Router,
  Switch,
  Route,
} from "react-router-dom";

import {
  Link,
  HStack,
} from '@chakra-ui/react';

import Login from "./components/Login/Login";
import About from "./components/About/About";

import User from "./components/User/User";
import Account from "./components/Account/Account";
import Resolution from "./components/Resolution/Resolution";
import Register from "./components/register/Register";
import Gig from "./components/Gig/Gig";

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
      url:'/account'
    },
    {
      text:'Register',
      url:'/register'
    },
    {
      text:'Find Freelancers',
      url:'/search/freelancers'
    },
    {
      text:'Find Gigs',
      url:'/search/gigs'
    },
    {
      text:'Resolution Center',
      url:'/resolution'
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
            <Route path="/login" component={Login} />
            <Route path="/account" component={Account} />
            <Route path="/register" component={Register} />
            <Route path="/search/freelancers" component={User} />
            <Route path="/search/gigs" component={Gig} />
            <Route path="/resolution" component={Resolution} />
            <Route path="/" component={About} />
          </Switch>
        </Router>
      </div>

  );
}
