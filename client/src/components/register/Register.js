import React, {useState} from "react";
import { Block, Box, Button, Container, Content, Icon, Form, Heading } from 'react-bulma-components'

export default function Register() {
    const [registrationState, setRegistrationState] = useState('');
    const [walletAddress, setWalletAddress] = useState(localStorage.getItem("wallet"));

    const props = {
        wallet: walletAddress
    };

    if (registrationState === 'pending') {
        setTimeout(() => {
            return setRegistrationState('success')
        }, 4000)
    }

    if (registrationState === 'success') {
        setTimeout(() => {
            window.location = 'http://localhost:3000/account';
        }, 2000)
    }



    return <div>
        <section>
            <Box style={{width: 500, margin: 'auto'}}>
                <Container>
                    <Heading>
                        Register your account
                    </Heading>
                        <Block>
                            {registrationState === 'error' ?  
                                <Container>
                                    <Content>
                                        <Heading>Something went wrong! Please try again. </Heading>
                                    </Content>
                                </Container>
                        : registrationState === 'pending' 
                        ? 
                            <Container>
                                <Content>
                                    <Heading size={4}>
                                     Please wait while we register your account. This should take about 30 seconds
                                    </Heading>
                                </Content>
                            </Container>
                       

                        : registrationState === 'success' 
                        ? 
                            <Container>
                                <Content>
                                    <Heading size={4}>You have successfully registered! </Heading>
                                </Content>
                            </Container>
                        

                        :                       
                        <form>
                            <Form.Field>
                            <Form.Label size={'small'}>Wallet Address</Form.Label>
                                <Form.Control>
                                    <Form.Input size={'small'} 
                                    type='text' 
                                    color='grey-light'
                                    disabled 
                                    readOnly
                                    placeholder={props.wallet} />
                                </Form.Control>
                            </Form.Field>
                            <Form.Field>
                            <Form.Label size={'small'}>Name</Form.Label>
                                <Form.Control>
                                    <Form.Input size={'small'} 
                                    type='text' 
                                    color='grey-light'
                                    placeholder='Your name' />
                                </Form.Control>
                            </Form.Field>
                            <Form.Field>
                                <Form.Label size={'small'}>Area</Form.Label>
                                <Form.Control>
                                    <Form.Input size={'small'} 
                                    type='text' 
                                    color='grey-light'
                                    placeholder='Your area' />
                                </Form.Control>
                            </Form.Field>
                            <Heading size={6}>
                                Social handles
                            </Heading>
                            <Form.Field>
                                <Form.Label size={'small'}>Telegram</Form.Label>
                                <Form.Control>
                                    <Form.Input size={'small'} 
                                    type='text' 
                                    color='grey-light'
                                    placeholder='Your Telegram handle' />
                                </Form.Control>
                            </Form.Field>
                            <Form.Field>
                                <Form.Label size={'small'}>Discord</Form.Label>
                                <Form.Control>
                                    <Form.Input size={'small'} 
                                    type='text' 
                                    color='grey-light'
                                    placeholder='Your Discord handle' />
                                </Form.Control>
                            </Form.Field>
                            <Form.Field>
                                <Form.Label size={'small'}>E-mail</Form.Label>
                                <Form.Control>
                                    <Form.Input size={'small'} 
                                    type='text' 
                                    color='grey-light'
                                    placeholder='Your e-mail address' />
                                </Form.Control>
                            </Form.Field>
                            <Form.Field>
                                <Form.Label size={'small'}>Github / Gitlab</Form.Label>
                                <Form.Control>
                                    <Form.Input size={'small'} 
                                    type='text' 
                                    color='grey-light'
                                    placeholder='Your Github or Gitlab profile' />
                                </Form.Control>
                            </Form.Field>
                            <Form.Field>
                                <Form.Label size={'small'}>Website</Form.Label>
                                <Form.Control>
                                    <Form.Input size={'small'} 
                                    type='text' 
                                    color='grey-light'
                                    placeholder='Your portfolio website link' />
                                </Form.Control>
                            </Form.Field>
                            <Form.Field >
                                <Form.Control>
                                    <Button color="link" size={'small'} onClick={() => setRegistrationState('pending')}>Submit</Button>
                                </Form.Control>
                            </Form.Field>
                        </form>    
                        }

                    </Block>
                </Container>
            </Box>

        </section>
    </div>;
}
