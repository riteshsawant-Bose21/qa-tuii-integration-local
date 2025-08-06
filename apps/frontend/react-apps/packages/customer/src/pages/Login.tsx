import { useEffect, useState } from 'react';
import {
    Box, Card, CardContent, Typography, TextField,
    Button, Link, Divider
} from '@mui/material';
import { styled } from '@mui/material/styles';
import splash from '../assets/splash.png';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const Container = styled('div')(({ theme }) => ({
    minHeight: '100vh',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    background: `linear-gradient(135deg, ${theme.palette.grey[200]} 0%, ${theme.palette.grey[300]} 100%)`,
}));
const StyledCard = styled(Card)(({ theme }) => ({ width: 540, boxShadow: theme.shadows[5] }));
const Splash = styled('div')(() => ({ height: 200, width: '100%', backgroundSize: 'cover', backgroundPosition: 'center' }));

export default function Login() {
    const { user, login, register, updateMetadata } = useAuth();
    const [hasRedirected, setHasRedirected] = useState(false);
    const nav = useNavigate();

    useEffect(() => {
        if (!hasRedirected && user?.metadata?.xyteApiKey) {
            setHasRedirected(true);
            nav('/dashboard', { replace: true });
        }
    }, [user, hasRedirected, nav]);

    /* auth form state */
    const [mode, setMode] = useState<'login' | 'register'>('login');
    const [email, setE] = useState(''); const [pw, setP] = useState('');
    /* xyte form state */
    const [apiKey, setK] = useState('');
    /* ui error */
    const [err, setErr] = useState('');

    const submitAuth = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            mode === 'login'
                ? await login(email, pw)
                : await register(email, pw);
            setErr('');
        } catch { setErr('Authentication failed'); }
    };

    const submitXyte = async () => {
        try {
            await updateMetadata({ xyteApiKey: apiKey.trim() });
            setErr('');
        } catch { setErr('Invalid API key'); }
    };
    return (
        <Container>
            <StyledCard>
                <Splash style={{ backgroundImage: `url(${splash})` }} />
                <CardContent sx={{ p: 3 }}>
                    {/* STEP 1: login / register */}
                    {!user && (
                        <>
                            <Typography variant="h5" textAlign="center" gutterBottom>
                                {mode === 'login' ? 'Sign In' : 'Create Account'}
                            </Typography>
                            <Box component="form" onSubmit={submitAuth}>
                                <TextField fullWidth label="Username / Email" sx={{ mb: 2 }} value={email} onChange={e => setE(e.target.value)} />
                                <TextField fullWidth label="Password" type="password" sx={{ mb: 2 }} value={pw} onChange={e => setP(e.target.value)} />
                                {err && <Typography color="error" sx={{ mb: 2 }}>{err}</Typography>}
                                <Button fullWidth variant="contained" type="submit">
                                    {mode === 'login' ? 'Log In' : 'Register'}
                                </Button>
                            </Box>
                            <Divider sx={{ my: 3 }} />
                            <Typography variant="body2" align="center">
                                {mode === 'login'
                                    ? <>Don’t have an account? <Link component="button" onClick={() => setMode('register')}>Register</Link></>
                                    : <>Already have an account? <Link component="button" onClick={() => setMode('login')}>Sign in</Link></>}
                            </Typography>
                        </>
                    )}

                    {/* STEP 2: ask for Xyte key (only if user logged in but key missing) */}
                    {user && (!user.metadata || !user.metadata.xyteApiKey) && (
                        <>
                            <Typography variant="h6" gutterBottom textAlign="center">
                                Welcome, {user.userId}
                            </Typography>
                            <Typography variant="body2" gutterBottom>
                                Enter your organization’s Xyte Core API key:
                            </Typography>
                            <Link href="https://docs.xyte.io/reference/core-api-keys" variant="caption" target="_blank">
                                How to obtain your API key
                            </Link>
                            <TextField fullWidth sx={{ mt: 2, mb: 2 }} label="Xyte API Key"
                                value={apiKey} onChange={e => setK(e.target.value)} />
                            {err && <Typography color="error" sx={{ mb: 2 }}>{err}</Typography>}
                            <Button fullWidth variant="contained" onClick={submitXyte}>Submit</Button>
                        </>
                    )}
                    { }
                </CardContent>
            </StyledCard>
        </Container>
    );
}
