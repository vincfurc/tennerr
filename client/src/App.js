import React, { useState } from "react";
import {
  BrowserRouter as Router,
  Switch,
  Route,
} from "react-router-dom";

import 'bulma/css/bulma.min.css';
import { 
  Navbar,
  Heading,
  Footer,
  Container,
  Content } from 'react-bulma-components';

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
      text:'Login',
      url:'/login'
    },
    {
      text:'My Account',
      url:'/account',
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

  const links = linkData.map((link, idx) => <Navbar.Item href={link.url} key={idx}>{link.text}</Navbar.Item> );

  const [isMenuOpen, handleMenu] = useState(false);

  function toggleMenu() {
    return handleMenu(!isMenuOpen);
  }

  return (
      <div>
        <Router>
          <Navbar active={isMenuOpen}>
            <Navbar.Brand>
              <Navbar.Item renderAs="a" href="./" >
                <Heading spaced={true} size={4} weight={'bold'}>
                  Tennerr
                </Heading>
              </Navbar.Item>
              <Navbar.Burger onClick={toggleMenu} />
            </Navbar.Brand>
            <Navbar.Menu>
              <Navbar.Container align="left">
                <Navbar.Item href='./'>Home</Navbar.Item>
              </Navbar.Container>
              <Navbar.Container align="right">
                {links}
              </Navbar.Container>
            </Navbar.Menu>
          </Navbar>
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
        <Footer>
            <Container>
              <Content style={{ textAlign: 'center' }}>
                <p>
                Tenner was made with <strong>♥</strong> by @vinc, @iso and @eurv
                </p>
              </Content>
            </Container>
          </Footer>
      </div>

  );
}
