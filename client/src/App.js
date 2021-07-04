import React, { useState } from "react";
import { BrowserRouter as Router, Switch, Route, Link } from "react-router-dom";

import "bulma/css/bulma.min.css";
import {
  Navbar,
  Heading,
  Footer,
  Container,
  Content,
} from "react-bulma-components";

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
      text: "Login",
      url: "/login",
      isLoggedIn: false,
    },
    {
      text: "My Account",
      url: "/account",
      isLoggedIn: true,
    },
    {
      text: "Register",
      url: "/register",
      isLoggedIn: false,
    },
    {
      text: "Find Freelancers",
      url: "/search/freelancers",
      isLoggedIn: true,
    },
    {
      text: "Find Gigs",
      url: "/search/gigs",
      isLoggedIn: true,
    },
    {
      text: "Resolution Center",
      url: "/resolution",
      isLoggedIn: true,
    },
  ];

  // let links = linkData.map((link, idx) => (
  //   <Navbar.Item renderAs="li" key={idx}>
  //     <Link to={link.url}>{link.text}</Link>
  //   </Navbar.Item>
  // ));

  const [isMenuOpen, handleMenu] = useState(false);
  const [isLoggedIn, handleLogin] = useState(false);

  function toggleMenu() {
    return handleMenu(!isMenuOpen);
  }

  function toggleLogin() {
    let login = !isLoggedIn;
    handleLogin(login);
    setMenuItems();
  }

  function setMenuItems() {
    return (linkData.map((link, idx) =>
      isLoggedIn === link.isLoggedIn 
      ? (<Navbar.Item renderAs="li" key={idx}>
          <Link to={link.url}>{link.text}</Link>
        </Navbar.Item>) 
      : null
    ));
  }

  return (
    <div>
      <Router>
        <Navbar active={isMenuOpen}>
          <Navbar.Brand>
            <Navbar.Item renderAs="a" href="./">
              <Heading spaced={true} size={4} weight={"bold"}>
                Tennerr
              </Heading>
            </Navbar.Item>
            <Navbar.Burger onClick={toggleMenu} />
          </Navbar.Brand>
          <Navbar.Menu>
            <Navbar.Container renderAs="ul" align="left">
              <Navbar.Item renderAs="li">
                <Link to="./">Home</Link>
              </Navbar.Item>
            </Navbar.Container>
            <Navbar.Container renderAs="ul" align="right">
              {setMenuItems()}
            </Navbar.Container>
          </Navbar.Menu>
        </Navbar>
        {/* A <Switch> looks through its children <Route>s and
            renders the first one that matches the current URL. */}
        <Switch>
          <Route path="/login">
            <Login user={toggleLogin}></Login>
          </Route>
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
          <Content style={{ textAlign: "center" }}>
            <p>
              Tenner was made with <strong>♥</strong> by @vinc, @iso and @eurv
            </p>
          </Content>
        </Container>
      </Footer>
    </div>
  );
}
