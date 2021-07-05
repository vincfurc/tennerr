import React, { useState } from "react";
import { BrowserRouter as Router, Switch, Route, Link } from "react-router-dom";

import "bulma/css/bulma.min.css";
import {
  Navbar,
  Heading,
  Footer,
  Container,
  Content,
  Section
} from "react-bulma-components";

import Login from "./components/Login/Login";
import About from "./components/About/About";

// import User from "./components/User/User";
import Search from "./components/Search/Search";
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
      isLoggedIn: true,
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

  const walletSet = (localStorage.getItem("wallet").length === 0 ? false : true);

  const [isMenuOpen, handleMenu] = useState(false);
  const [isLoggedIn, handleLogin] = useState(walletSet);

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
      ? <Navbar.Item href={link.url} key={idx}> {link.text}</Navbar.Item> 
      : null
    ));
  }

  return (
    <div>
      <Router>
        <Navbar 
        active={isMenuOpen}
        fixed='top' color='info has-shadow' >
          <Container breakpoint='desktop is-max-desktop' >
          <Navbar.Brand>
            <Navbar.Item renderAs="a" href="./">
              <Heading style={{color: 'white'}} spaced={true} size={4} weight={"bold"} >
                Tennerr
              </Heading>
            </Navbar.Item>
            <Navbar.Burger onClick={toggleMenu} />
          </Navbar.Brand>
          <Navbar.Menu>
            <Navbar.Container align="left">
              <Navbar.Item href="./">Home
              </Navbar.Item>
            </Navbar.Container>
            <Navbar.Container renderAs="ul" align="right">
              {setMenuItems()}
            </Navbar.Container>
          </Navbar.Menu>
          </Container>

        </Navbar>
        {/* A <Switch> looks through its children <Route>s and
            renders the first one that matches the current URL. */}
        <Section >
          <Container 
          breakpoint='desktop is-max-desktop'>
            <Switch>
              <Route path="/login">
                <Login user={toggleLogin}></Login>
              </Route>
              <Route path="/account" component={Account} />
              <Route path="/register" component={Register} />
              <Route path="/search/freelancers" component={Search} />
              <Route path="/search/gigs" component={Gig} />
              <Route path="/resolution" component={Resolution} />
              <Route path="/" component={About} />
            </Switch>
          </Container>
        </Section>

      </Router>
      <Footer>
        <Container breakpoint='desktop is-max-desktopp'>
          <Content style={{ textAlign: "center" }}
          >
            <p>
              Tenner was made with <strong>♥</strong> by @vinc, @iso and @eurv
            </p>
          </Content>
        </Container>
      </Footer>
    </div>
  );
}
