
import { Card } from '@mui/material';
import { styled } from '@mui/material/styles';
import splashImage from '../assets/splash.png';
import { useAuth } from 'react-oidc-context';
import { useEffect } from 'react';

const Container = styled('div')(({ theme }) => ({
    minHeight: '100vh',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    background: `linear-gradient(135deg, ${theme.palette.grey[200]} 0%, ${theme.palette.grey[300]} 100%)`,
}));

const StyledCard = styled(Card)(({ theme }) => ({
    width: 540,
    boxShadow: theme.shadows[5],
}));

const SplashContainer = styled('div')(() => ({
    width: '100%',
    height: 200,
    backgroundSize: 'cover',
    backgroundPosition: 'center',
    borderTopLeftRadius: 4,
    borderTopRightRadius: 4,
}));

export default function AuthRedirect() {
    const auth = useAuth();

    useEffect(() => {
        auth.signinRedirect();
    }, []);

    return (
        <Container>
            <StyledCard>
                <SplashContainer
                    style={{
                        backgroundImage: `url(${splashImage})`,
                    }}
                />
            </StyledCard>
        </Container>
    );
}
